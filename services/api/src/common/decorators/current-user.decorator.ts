import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { UserRole } from '@prisma/client';

export const CurrentUser = createParamDecorator((data: keyof JwtPayload | undefined, ctx: ExecutionContext) => {
  const req = ctx.switchToHttp().getRequest<{ user: JwtPayload }>();
  return data ? req.user[data] : req.user;
});

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
}
