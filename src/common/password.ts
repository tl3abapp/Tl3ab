import { randomBytes, scryptSync, timingSafeEqual } from 'crypto';

const KEY_LENGTH = 64;
const SALT_BYTES = 16;

export function hashPassword(password: string): string {
  const salt = randomBytes(SALT_BYTES).toString('hex');
  const hash = scryptSync(password, salt, KEY_LENGTH).toString('hex');
  return `${salt}:${hash}`;
}

export function verifyPassword(password: string, storedValue: string): boolean {
  const [salt, hash] = storedValue.split(':');
  if (!salt || !hash) {
    return false;
  }

  try {
    const hashBuffer = Buffer.from(hash, 'hex');
    const checkBuffer = scryptSync(password, salt, KEY_LENGTH);
    if (hashBuffer.length != checkBuffer.length) {
      return false;
    }
    return timingSafeEqual(hashBuffer, checkBuffer);
  } catch {
    return false;
  }
}
