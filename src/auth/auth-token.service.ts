import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createHmac, timingSafeEqual } from 'node:crypto';

type TokenPayload = {
  sub: string;
  exp: number;
};

@Injectable()
export class AuthTokenService {
  private readonly secret =
    process.env.AUTH_TOKEN_SECRET ||
    process.env.JWT_SECRET ||
    'tl3ab-local-dev-token-secret-change-me';

  private readonly ttlSeconds = Number(
    process.env.AUTH_TOKEN_TTL_SECONDS ?? 60 * 60 * 24 * 30,
  );

  signUser(userId: string): string {
    const header = this.base64UrlJson({ alg: 'HS256', typ: 'JWT' });
    const payload = this.base64UrlJson({
      sub: userId,
      exp: Math.floor(Date.now() / 1000) + this.ttlSeconds,
    });
    const signature = this.sign(`${header}.${payload}`);
    return `${header}.${payload}.${signature}`;
  }

  verify(token: string): TokenPayload {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Invalid auth token');
    }

    const [header, payload, signature] = parts;
    const expected = this.sign(`${header}.${payload}`);
    if (!this.safeEqual(signature, expected)) {
      throw new UnauthorizedException('Invalid auth token');
    }

    const decoded = JSON.parse(
      Buffer.from(payload, 'base64url').toString('utf8'),
    ) as TokenPayload;
    if (!decoded.sub || !decoded.exp || decoded.exp < Date.now() / 1000) {
      throw new UnauthorizedException('Auth token expired');
    }

    return decoded;
  }

  private base64UrlJson(value: unknown): string {
    return Buffer.from(JSON.stringify(value)).toString('base64url');
  }

  private sign(value: string): string {
    return createHmac('sha256', this.secret).update(value).digest('base64url');
  }

  private safeEqual(left: string, right: string): boolean {
    const leftBuffer = Buffer.from(left);
    const rightBuffer = Buffer.from(right);
    return (
      leftBuffer.length === rightBuffer.length &&
      timingSafeEqual(leftBuffer, rightBuffer)
    );
  }
}
