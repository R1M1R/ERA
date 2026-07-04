"""LSB steganography utilities with server-side proof-of-authenticity seals."""

from __future__ import annotations

import hashlib
import json
import os
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Final

from PIL import Image

DEFAULT_WIDTH: Final[int] = 512
DEFAULT_HEIGHT: Final[int] = 512
_LENGTH_PREFIX_BYTES: Final[int] = 4
_AUTHENTICITY_HASH_LENGTH: Final[int] = 64


class SteganographyError(ValueError):
    """Raised when steganographic encoding or decoding fails."""


@dataclass(frozen=True, slots=True)
class AuthenticatedPayload:
    """Decoded steganographic payload with an embedded authenticity seal."""

    text: str
    authenticity_hash: str


def get_server_salt() -> str:
    """Return the server secret salt used for authenticity hashing."""
    salt = os.getenv("ERA_SERVER_SALT", "").strip()
    if not salt:
        raise SteganographyError(
            "ERA_SERVER_SALT is not configured. Set a secret salt in the environment."
        )
    return salt


def compute_authenticity_hash(text: str, *, salt: str | None = None) -> str:
    """Compute SHA-256(text + server salt) for proof-of-authenticity sealing."""
    secret = salt if salt is not None else get_server_salt()
    digest = hashlib.sha256()
    digest.update(text.encode("utf-8"))
    digest.update(secret.encode("utf-8"))
    return digest.hexdigest()


def build_authenticated_message(text: str) -> tuple[str, str]:
    """Build the JSON message embedded into artifacts and return its authenticity hash."""
    authenticity_hash = compute_authenticity_hash(text)
    message = json.dumps(
        {"text": text, "authenticity_hash": authenticity_hash},
        ensure_ascii=False,
    )
    return message, authenticity_hash


class SteganographyGenerator:
    """Generate procedural canvases and hide authenticated payloads via RGB LSB."""

    def __init__(
        self,
        width: int = DEFAULT_WIDTH,
        height: int = DEFAULT_HEIGHT,
    ) -> None:
        if width <= 0 or height <= 0:
            raise SteganographyError("Canvas width and height must be positive integers.")

        self.width = width
        self.height = height
        self._capacity_bits = width * height * 3
        self._capacity_bytes = self._capacity_bits // 8

    def encode_authenticated_text_to_image(
        self,
        text: str,
        output_path: str | Path,
        *,
        seed: str | int | None = None,
    ) -> tuple[Path, str]:
        """Seal ``text`` with a server-side hash and embed both into an image."""
        message, authenticity_hash = build_authenticated_message(text)
        image_path = self.encode_text_to_image(message, output_path, seed=seed)
        return image_path, authenticity_hash

    def encode_text_to_image(
        self,
        text: str,
        output_path: str | Path,
        *,
        seed: str | int | None = None,
    ) -> Path:
        """Embed ``text`` into a procedural RGB image using LSB steganography."""
        payload = text.encode("utf-8")
        message = struct.pack(">I", len(payload)) + payload
        bits = "".join(f"{byte:08b}" for byte in message)

        if len(bits) > self._capacity_bits:
            raise SteganographyError(
                f"Payload requires {len(bits)} bits, but canvas capacity is "
                f"{self._capacity_bits} bits ({self._capacity_bytes} bytes)."
            )

        noise_seed = self._resolve_seed(seed, text)
        image = self._generate_procedural_noise(noise_seed)
        pixels = image.load()

        if pixels is None:
            raise SteganographyError("Failed to access pixel buffer for encoding.")

        bit_index = 0
        for y in range(self.height):
            for x in range(self.width):
                if bit_index >= len(bits):
                    break

                red, green, blue = pixels[x, y]
                channels = [red, green, blue]

                for channel_idx in range(3):
                    if bit_index >= len(bits):
                        break
                    channels[channel_idx] = (channels[channel_idx] & 0xFE) | int(bits[bit_index])
                    bit_index += 1

                pixels[x, y] = tuple(channels)

        destination = Path(output_path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination, format="PNG")
        return destination.resolve()

    def decode_text_from_image(self, image_path: str | Path) -> str:
        """Extract a UTF-8 payload previously embedded with LSB steganography."""
        image = Image.open(image_path).convert("RGB")
        return self.decode_text_from_image_object(image)

    def decode_text_from_image_object(self, image: Image.Image) -> str:
        """Extract a UTF-8 payload from an in-memory RGB image."""
        pixels = image.load()

        if pixels is None:
            raise SteganographyError("Failed to access pixel buffer for decoding.")

        width, height = image.size
        bits: list[str] = []

        for y in range(height):
            for x in range(width):
                red, green, blue = pixels[x, y]
                bits.append(str(red & 1))
                bits.append(str(green & 1))
                bits.append(str(blue & 1))

        if len(bits) < _LENGTH_PREFIX_BYTES * 8:
            raise SteganographyError("Image does not contain a valid steganographic header.")

        bit_string = "".join(bits)
        length = struct.unpack(">I", self._bits_to_bytes(bit_string[:32]))[0]
        required_bits = 32 + length * 8

        if length == 0:
            return ""

        if required_bits > len(bit_string):
            raise SteganographyError("Truncated steganographic payload detected.")

        payload_bytes = self._bits_to_bytes(bit_string[32:required_bits])

        try:
            return payload_bytes.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise SteganographyError("Decoded payload is not valid UTF-8.") from exc

    def decode_authenticated_payload(self, image_path: str | Path) -> AuthenticatedPayload:
        """Extract text and authenticity hash from a sealed artifact image."""
        image = Image.open(image_path).convert("RGB")
        return self.decode_authenticated_payload_from_image(image)

    def decode_authenticated_payload_from_image(self, image: Image.Image) -> AuthenticatedPayload:
        """Extract text and authenticity hash from an in-memory artifact image."""
        raw_payload = self.decode_text_from_image_object(image)
        return self.parse_authenticated_payload(raw_payload)

    @staticmethod
    def parse_authenticated_payload(raw_payload: str) -> AuthenticatedPayload:
        """Parse a JSON payload containing text and an authenticity hash."""
        try:
            payload: dict[str, Any] = json.loads(raw_payload)
        except json.JSONDecodeError as exc:
            raise SteganographyError("Artifact payload is not a valid authenticated message.") from exc

        text = str(payload.get("text", "")).strip()
        authenticity_hash = str(payload.get("authenticity_hash", "")).strip().lower()

        if not text:
            raise SteganographyError("Authenticated payload is missing text.")
        if len(authenticity_hash) != _AUTHENTICITY_HASH_LENGTH:
            raise SteganographyError("Authenticated payload contains an invalid hash seal.")

        return AuthenticatedPayload(text=text, authenticity_hash=authenticity_hash)

    def _resolve_seed(self, seed: str | int | None, text: str) -> int:
        if isinstance(seed, int):
            return seed & 0xFFFFFFFF
        if isinstance(seed, str):
            digest = hashlib.sha256(seed.encode("utf-8")).digest()
            return int.from_bytes(digest[:4], "big")

        digest = hashlib.sha256(text.encode("utf-8")).digest()
        return int.from_bytes(digest[:4], "big")

    def _generate_procedural_noise(self, seed: int) -> Image.Image:
        image = Image.new("RGB", (self.width, self.height))
        pixels = image.load()

        if pixels is None:
            raise SteganographyError("Failed to allocate procedural noise canvas.")

        state = seed or 1

        for y in range(self.height):
            for x in range(self.width):
                state = (1_103_515_245 * state + 12_345) & 0xFFFFFFFF
                noise = (state >> 16) & 0xFF

                harmonic = (
                    (((x * 17 + y * 31) ^ ((x >> 2) + (y >> 2))) & 0xFF)
                    + ((x * y) % 97)
                ) & 0xFF

                red = (noise * 3 + harmonic * 2 + 48) % 256
                green = (noise * 2 + harmonic + 72) % 256
                blue = (noise + harmonic * 2 + 96) % 256
                pixels[x, y] = (red, green, blue)

        return image

    @staticmethod
    def _bits_to_bytes(bits: str) -> bytes:
        padded = bits + "0" * ((8 - len(bits) % 8) % 8)
        return bytes(int(padded[index : index + 8], 2) for index in range(0, len(padded), 8))
