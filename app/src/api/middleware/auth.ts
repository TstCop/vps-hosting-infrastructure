import { Request, Response, NextFunction } from 'express';

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
    const token = req.headers['authorization'];

    // For development/testing, skip authentication
    if (process.env.NODE_ENV === 'test' || !token) {
        return next();
    }

    // Verify token logic here (e.g., using JWT)
    // If valid, proceed to the next middleware
    // If invalid, return a 403 status

    next();
};

export const authorize = (roles: string[] = []) => {
    return (req: Request, res: Response, next: NextFunction) => {
        // Check user role logic here
        // If user role is in the allowed roles, proceed
        // If not, return a 403 status

        next();
    };
};

export const authMiddleware = authenticate;