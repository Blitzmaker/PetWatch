import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already exists');
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({ data: { email: dto.email, passwordHash } });
    return this.issueTokens(user.id, user.email);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) throw new UnauthorizedException('Invalid credentials');
    return this.issueTokens(user.id, user.email);
  }

  async refresh(dto: RefreshDto) {
    const payload = await this.verifyRefresh(dto.refreshToken);
    const token = await this.prisma.refreshToken.findFirst({ where: { userId: payload.sub } });
    if (!token || !(await bcrypt.compare(dto.refreshToken, token.tokenHash)) || token.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid refresh token');
    }
    await this.prisma.refreshToken.delete({ where: { id: token.id } });
    return this.issueTokens(payload.sub, payload.email);
  }

  async logout(userId: string) {
    await this.prisma.refreshToken.deleteMany({ where: { userId } });
  }

  private async issueTokens(userId: string, email: string) {
    const accessToken = await this.jwtService.signAsync(
      { sub: userId, email },
      { secret: this.configService.getOrThrow<string>('JWT_ACCESS_SECRET'), expiresIn: this.configService.get<string>('JWT_ACCESS_EXPIRES_IN', '15m') },
    );
    const refreshToken = await this.jwtService.signAsync(
      { sub: userId, email },
      { secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'), expiresIn: `${this.configService.get<string>('JWT_REFRESH_EXPIRES_IN_DAYS', '30')}d` },
    );
    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: await bcrypt.hash(refreshToken, 10),
        expiresAt: new Date(Date.now() + Number(this.configService.get('JWT_REFRESH_EXPIRES_IN_DAYS', '30')) * 24 * 60 * 60 * 1000),
      },
    });
    return { user: { id: userId, email }, accessToken, refreshToken };
  }

  private async verifyRefresh(token: string): Promise<{ sub: string; email: string }> {
    try {
      return await this.jwtService.verifyAsync(token, { secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET') });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}
