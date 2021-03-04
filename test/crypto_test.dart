import 'dart:convert';

import 'package:cryptography/cryptography.dart';

void main() {
  var codec = AsciiCodec(allowInvalid: true);
  final message = codec.encode('Foobar');

  // AES-CTR is NOT authenticated,
  // so we should use some MAC algorithm such as HMAC-SHA256.
  final cipher = AesCtr.with128bits(macAlgorithm: MacAlgorithm.empty);

  // Choose some secret key and nonce
  final secretKey = cipher.newSecretKey();
  //final nonce = Nonce([39, 176, 174, 16, 52, 190, 21, 114, 238, 207, 135, 161, 190, 196, 225, 130]);

  // Encrypt
  /*final encrypted = cipher.encryptSync(
    message,
    secretKey: secretKey,
    nonce: nonce,
  );

  print(encrypted);
  encrypted[0] = 13;

  // Decrypt
  final decrypted = cipher.decryptSync(
    encrypted,
    secretKey: secretKey,
    nonce: nonce,
  );

  print(codec.decode(decrypted));
   */
}
