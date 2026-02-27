import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { JwtPayload } from '../decorators/current-user.decorator';

const roleOrder: Record<UserRole, number> = {
  USER: 0,
  MODERATOR: 1,
  CURATOR: 2,
  FOOD_REVIEWER: 3,
  ADMIN: 4,
};

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!roles || roles.length === 0) {
      return true;
    }

    const req = context.switchToHttp().getRequest<{ user?: JwtPayload }>();
    if (!req.user?.role) {
      return false;
    }

    return roles.some((requiredRole) => roleOrder[req.user!.role] >= roleOrder[requiredRole]);
  }
}
