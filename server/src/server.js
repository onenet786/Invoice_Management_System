import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import pg from 'pg';

const requiredEnvironment = ['DATABASE_URL', 'JWT_SECRET', 'GOOGLE_OAUTH_CLIENT_IDS'];
for (const key of requiredEnvironment) {
  if (!process.env[key]) throw new Error(`${key} is required.`);
}

const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const googleClient = new OAuth2Client();
const googleClientIds = process.env.GOOGLE_OAUTH_CLIENT_IDS.split(',').map((value) => value.trim());
const allowedOrigins = process.env.CORS_ORIGINS?.split(',').map((value) => value.trim()) ?? [];
const app = express();

app.use(cors({ origin: allowedOrigins.length ? allowedOrigins : false }));
app.use(express.json({ limit: '5mb' }));

function requireSession(request, response, next) {
  const token = request.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return response.status(401).json({ error: 'Missing session token.' });
  try {
    request.session = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    response.status(401).json({ error: 'Invalid or expired session token.' });
  }
}

app.get('/health', async (_request, response) => {
  await pool.query('SELECT 1');
  response.json({ status: 'ok' });
});

app.post('/v1/auth/google', async (request, response) => {
  const idToken = request.body?.idToken;
  if (typeof idToken !== 'string' || idToken.length === 0) {
    return response.status(400).json({ error: 'Google ID token is required.' });
  }

  const ticket = await googleClient.verifyIdToken({ idToken, audience: googleClientIds });
  const profile = ticket.getPayload();
  if (!profile?.sub || !profile.email || !profile.email_verified) {
    return response.status(401).json({ error: 'Google account email is not verified.' });
  }

  const result = await pool.query(
    `INSERT INTO app_users (google_subject, email, display_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (google_subject) DO UPDATE
       SET email = EXCLUDED.email, display_name = EXCLUDED.display_name, updated_at = NOW()
     RETURNING id, email, display_name`,
    [profile.sub, profile.email, profile.name ?? null],
  );
  const user = result.rows[0];
  const sessionToken = jwt.sign({ sub: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '30d' });
  response.json({ token: sessionToken, user });
});

app.get('/v1/workspace', requireSession, async (request, response) => {
  const result = await pool.query(
    'SELECT revision, payload, updated_at FROM workspaces WHERE user_id = $1',
    [request.session.sub],
  );
  const workspace = result.rows[0] ?? { revision: 0, payload: null, updated_at: null };
  response.json(workspace);
});

app.put('/v1/workspace', requireSession, async (request, response) => {
  const payload = request.body?.payload;
  const expectedRevision = request.body?.expectedRevision;
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return response.status(400).json({ error: 'Workspace payload must be an object.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const existing = await client.query(
      'SELECT revision FROM workspaces WHERE user_id = $1 FOR UPDATE',
      [request.session.sub],
    );
    const currentRevision = existing.rows[0]?.revision ?? 0;
    if (expectedRevision != null && Number(expectedRevision) !== Number(currentRevision)) {
      await client.query('ROLLBACK');
      return response.status(409).json({ error: 'Workspace changed on another device.', revision: currentRevision });
    }
    const nextRevision = Number(currentRevision) + 1;
    const saved = await client.query(
      `INSERT INTO workspaces (user_id, revision, payload)
       VALUES ($1, $2, $3::jsonb)
       ON CONFLICT (user_id) DO UPDATE
         SET revision = EXCLUDED.revision, payload = EXCLUDED.payload, updated_at = NOW()
       RETURNING revision, updated_at`,
      [request.session.sub, nextRevision, JSON.stringify(payload)],
    );
    await client.query('COMMIT');
    response.json(saved.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

app.use((error, _request, response, _next) => {
  console.error(error);
  response.status(500).json({ error: 'Unexpected server error.' });
});

app.listen(Number(process.env.PORT ?? 3000), () => {
  console.log(`Invoicey sync API listening on port ${process.env.PORT ?? 3000}`);
});
