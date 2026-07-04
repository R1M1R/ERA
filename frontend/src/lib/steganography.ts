/**
 * Client-side LSB decoder matching the backend SteganographyGenerator format.
 * Payload layout: [4-byte big-endian length][utf-8 bytes], 3 bits per RGB pixel.
 */

export class SteganographyDecodeError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'SteganographyDecodeError'
  }
}

function bitsToBytes(bits: string): Uint8Array {
  const padded = bits + '0'.repeat((8 - (bits.length % 8)) % 8)
  const bytes = new Uint8Array(padded.length / 8)

  for (let index = 0; index < padded.length; index += 8) {
    bytes[index / 8] = Number.parseInt(padded.slice(index, index + 8), 2)
  }

  return bytes
}

export function decodeTextFromImageData(imageData: ImageData): string {
  const bits: string[] = []
  const { data, width, height } = imageData

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const offset = (y * width + x) * 4
      bits.push(String(data[offset] & 1))
      bits.push(String(data[offset + 1] & 1))
      bits.push(String(data[offset + 2] & 1))
    }
  }

  if (bits.length < 32) {
    throw new SteganographyDecodeError('Image does not contain a valid steganographic header.')
  }

  const bitString = bits.join('')
  const lengthBytes = bitsToBytes(bitString.slice(0, 32))
  const length = new DataView(lengthBytes.buffer, lengthBytes.byteOffset, lengthBytes.byteLength).getUint32(0, false)

  if (length === 0) {
    return ''
  }

  const requiredBits = 32 + length * 8
  if (requiredBits > bitString.length) {
    throw new SteganographyDecodeError('Truncated steganographic payload detected.')
  }

  const payloadBytes = bitsToBytes(bitString.slice(32, requiredBits))

  try {
    return new TextDecoder('utf-8', { fatal: true }).decode(payloadBytes.subarray(0, length))
  } catch {
    throw new SteganographyDecodeError('Decoded payload is not valid UTF-8.')
  }
}

function loadImageFromFile(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const objectUrl = URL.createObjectURL(file)
    const image = new Image()

    image.onload = () => {
      URL.revokeObjectURL(objectUrl)
      resolve(image)
    }

    image.onerror = () => {
      URL.revokeObjectURL(objectUrl)
      reject(new SteganographyDecodeError('Failed to load image file.'))
    }

    image.src = objectUrl
  })
}

export async function decodeTextFromImageFile(file: File): Promise<string> {
  const image = await loadImageFromFile(file)
  const canvas = document.createElement('canvas')
  canvas.width = image.naturalWidth
  canvas.height = image.naturalHeight

  const context = canvas.getContext('2d', { willReadFrequently: true })
  if (!context) {
    throw new SteganographyDecodeError('Canvas API is not available in this browser.')
  }

  context.drawImage(image, 0, 0)
  const imageData = context.getImageData(0, 0, canvas.width, canvas.height)
  return decodeTextFromImageData(imageData)
}
