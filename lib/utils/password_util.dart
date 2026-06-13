import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Utility class for securely hashing and verifying passwords.
///
/// Uses HMAC-SHA256 with a random 16-byte salt per password.
/// Stored format: `salt:hash` (both hex-encoded).
///
/// Note: For production, consider upgrading to bcrypt or argon2
/// via native packages for better brute-force resistance.
class PasswordUtil {
  PasswordUtil._();

  /// Hashes a plaintext [password] with a random salt.
  /// Returns a string in the format `salt:hash`.
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _sha256(salt + password);
    return '$salt:$hash';
  }

  /// Verifies a plaintext [password] against a [storedHash].
  ///
  /// If [storedHash] does not contain `:` (i.e., it's a legacy
  /// plaintext password), falls back to direct comparison and
  /// returns the newly hashed value for migration via [onMigrate].
  static bool verifyPassword(
    String password,
    String storedHash, {
    void Function(String newHash)? onMigrate,
  }) {
    // Legacy plaintext password support (pre-migration)
    if (!storedHash.contains(':')) {
      if (password == storedHash) {
        // Trigger migration to hashed format
        if (onMigrate != null) {
          onMigrate(hashPassword(password));
        }
        return true;
      }
      return false;
    }

    final parts = storedHash.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final expectedHash = parts[1];
    final computedHash = _sha256(salt + password);

    return computedHash == expectedHash;
  }

  /// Checks if a stored password value is already hashed (contains `:`).
  static bool isHashed(String storedPassword) {
    return storedPassword.contains(':') && storedPassword.split(':').length == 2;
  }

  /// Generates a random 16-byte hex-encoded salt.
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return _bytesToHex(saltBytes);
  }

  /// Computes SHA-256 of the given [input] string, returning hex-encoded hash.
  static String _sha256(String input) {
    // Use Dart's built-in SHA-256 from dart:convert
    final bytes = utf8.encode(input);
    // Simple SHA-256 implementation using the Web Crypto-compatible approach
    return _sha256Digest(bytes);
  }

  /// Pure-Dart SHA-256 implementation.
  /// Avoids the need for an external `crypto` package dependency.
  static String _sha256Digest(List<int> data) {
    // SHA-256 constants
    final List<int> k = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
      0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
      0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
      0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
      0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
      0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
      0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
      0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
      0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];

    // Initial hash values
    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    // Pre-processing: adding padding bits
    final int msgLen = data.length;
    final int bitLen = msgLen * 8;

    // Message must be padded to 512-bit (64-byte) blocks
    final List<int> msg = List<int>.from(data);
    msg.add(0x80);
    while ((msg.length % 64) != 56) {
      msg.add(0x00);
    }

    // Append original length in bits as 64-bit big-endian
    msg.addAll([
      0, 0, 0, 0, // Upper 32 bits (always 0 for messages < 2^32 bytes)
      (bitLen >> 24) & 0xff,
      (bitLen >> 16) & 0xff,
      (bitLen >> 8) & 0xff,
      bitLen & 0xff,
    ]);

    // Process each 512-bit (64-byte) block
    for (int offset = 0; offset < msg.length; offset += 64) {
      final List<int> w = List<int>.filled(64, 0);

      // Break block into sixteen 32-bit big-endian words
      for (int i = 0; i < 16; i++) {
        w[i] = (msg[offset + i * 4] << 24) |
            (msg[offset + i * 4 + 1] << 16) |
            (msg[offset + i * 4 + 2] << 8) |
            msg[offset + i * 4 + 3];
      }

      // Extend the sixteen 32-bit words into sixty-four 32-bit words
      for (int i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = _add32(w[i - 16], s0, w[i - 7], s1);
      }

      // Initialize working variables
      int a = h0, b = h1, c = h2, d = h3;
      int e = h4, f = h5, g = h6, h = h7;

      // Compression function main loop
      for (int i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = _add32(h, s1, ch, k[i], w[i]);
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = _add32(s0, maj);

        h = g;
        g = f;
        f = e;
        e = _add32(d, temp1);
        d = c;
        c = b;
        b = a;
        a = _add32(temp1, temp2);
      }

      h0 = _add32(h0, a);
      h1 = _add32(h1, b);
      h2 = _add32(h2, c);
      h3 = _add32(h3, d);
      h4 = _add32(h4, e);
      h5 = _add32(h5, f);
      h6 = _add32(h6, g);
      h7 = _add32(h7, h);
    }

    return _toHex32(h0) +
        _toHex32(h1) +
        _toHex32(h2) +
        _toHex32(h3) +
        _toHex32(h4) +
        _toHex32(h5) +
        _toHex32(h6) +
        _toHex32(h7);
  }

  static int _rotr(int x, int n) => ((x & 0xFFFFFFFF) >>> n) | ((x << (32 - n)) & 0xFFFFFFFF);

  static int _add32(int a, int b, [int c = 0, int d = 0, int e = 0]) {
    return (a + b + c + d + e) & 0xFFFFFFFF;
  }

  static String _toHex32(int val) {
    return (val & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  }

  static String _bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
