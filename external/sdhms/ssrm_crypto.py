#!/usr/bin/env python3
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
ssrm_crypto.py - Decrypt/encrypt Samsung SSRM (SIOP) policy files

Usage:
    Decrypt:
        python3 ssrm_crypto.py decrypt ssrm_default ssrm_default.xml
        python3 ssrm_crypto.py decrypt ssrm_default ssrm_default.xml --key siop_a36xq_sm6475

    Re-encrypt after editing (use the same key string):
        python3 ssrm_crypto.py encrypt ssrm_default.xml ssrm_default_patched --key siop_a36xq_sm6475

Notes:
    SDHMS takes the ssrm string(key) from floating feature(SEC_FLOATING_FEATURE_SYSTEM_CONFIG_SIOP_POLICY_FILENAME)
    If none is detected it fallbacks to it's hardcoded one
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
import argparse
import hashlib
import os
import sys

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

DEFAULT_KEY_STRING = "siop_a36xq_sm6475"


def derive_key(key_string: str) -> bytes:
    return hashlib.sha256(key_string.encode("utf-8")).digest()


def decrypt(in_path: str, out_path: str, key_string: str) -> None:
    with open(in_path, "rb") as f:
        data = f.read()

    if len(data) < 16:
        raise ValueError("Input file too short to contain a 16-byte IV")

    iv, ciphertext = data[:16], data[16:]
    key = derive_key(key_string)

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    decryptor = cipher.decryptor()
    padded = decryptor.update(ciphertext) + decryptor.finalize()

    unpadder = padding.PKCS7(128).unpadder()
    plaintext = unpadder.update(padded) + unpadder.finalize()

    with open(out_path, "wb") as f:
        f.write(plaintext)

    print(f"Decrypted {len(data)} bytes -> {len(plaintext)} bytes plaintext")
    print(f"Used key string: {key_string!r}")
    print(f"Wrote: {out_path}")


def encrypt(in_path: str, out_path: str, key_string: str) -> None:
    with open(in_path, "rb") as f:
        plaintext = f.read()

    key = derive_key(key_string)
    iv = os.urandom(16)  # fresh random IV each time, as the original does

    padder = padding.PKCS7(128).padder()
    padded = padder.update(plaintext) + padder.finalize()

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(padded) + encryptor.finalize()

    with open(out_path, "wb") as f:
        f.write(iv + ciphertext)

    print(f"Encrypted {len(plaintext)} bytes -> {len(iv) + len(ciphertext)} bytes")
    print(f"Used key string: {key_string!r}")
    print(f"Wrote: {out_path}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["decrypt", "encrypt"])
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--key", default=DEFAULT_KEY_STRING,
                     help=f"key string (default: {DEFAULT_KEY_STRING!r})")
    args = ap.parse_args()

    try:
        if args.mode == "decrypt":
            decrypt(args.input, args.output, args.key)
        else:
            encrypt(args.input, args.output, args.key)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
