import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { ApiResponse } from '../../types';

interface User {
    id: string;
    name: string;
    email: string;
    role: string;
    password: string;
    createdAt: string;
    updatedAt: string;
}

interface LoginRequest {
    email: string;
    password: string;
}

class AuthController {
    // Mock users database - in production this would be from a real database
    private users: User[] = [
        {
            id: 'user-1',
            name: 'Admin User',
            email: 'admin@exemplo.com',
            password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
            role: 'admin',
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-12-19T15:30:00Z'
        },
        {
            id: 'user-2',
            name: 'João Silva',
            email: 'joao@empresa.com',
            password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
            role: 'user',
            createdAt: '2024-01-15T10:00:00Z',
            updatedAt: '2024-12-19T15:30:00Z'
        }
    ];

    private generateToken(user: User): string {
        const payload = {
            id: user.id,
            email: user.email,
            role: user.role
        };
        
        return jwt.sign(payload, process.env.JWT_SECRET || 'your-secret-key', {
            expiresIn: '24h'
        });
    }

    private getUserFromToken(token: string): any {
        try {
            return jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
        } catch (error) {
            return null;
        }
    }

    async login(req: Request, res: Response): Promise<void> {
        try {
            const { email, password }: LoginRequest = req.body;

            // Validate input
            if (!email || !password) {
                res.status(400).json({
                    success: false,
                    error: 'Email and password are required',
                    message: 'Please provide both email and password'
                } as ApiResponse<null>);
                return;
            }

            // Find user
            const user = this.users.find(u => u.email === email);
            if (!user) {
                res.status(401).json({
                    success: false,
                    error: 'Invalid credentials',
                    message: 'Email or password is incorrect'
                } as ApiResponse<null>);
                return;
            }

            // Check password
            const isValidPassword = await bcrypt.compare(password, user.password);
            if (!isValidPassword) {
                res.status(401).json({
                    success: false,
                    error: 'Invalid credentials', 
                    message: 'Email or password is incorrect'
                } as ApiResponse<null>);
                return;
            }

            // Generate token
            const token = this.generateToken(user);

            // Return user data without password
            const { password: _, ...userWithoutPassword } = user;

            res.status(200).json({
                success: true,
                data: {
                    token,
                    user: userWithoutPassword
                },
                message: 'Login successful'
            } as ApiResponse<{ token: string; user: Omit<User, 'password'> }>);
        } catch (error) {
            console.error('Login error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong during login'
            } as ApiResponse<null>);
        }
    }

    async logout(req: Request, res: Response): Promise<void> {
        try {
            // In a real application, you might want to blacklist the token
            res.status(200).json({
                success: true,
                data: null,
                message: 'Logout successful'
            } as ApiResponse<null>);
        } catch (error) {
            console.error('Logout error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong during logout'
            } as ApiResponse<null>);
        }
    }

    async getCurrentUser(req: Request, res: Response): Promise<void> {
        try {
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'No token provided'
                } as ApiResponse<null>);
                return;
            }

            const token = authHeader.substring(7);
            const decoded = this.getUserFromToken(token);
            
            if (!decoded) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'Invalid token'
                } as ApiResponse<null>);
                return;
            }

            // Find user
            const user = this.users.find(u => u.id === decoded.id);
            if (!user) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not found'
                } as ApiResponse<null>);
                return;
            }

            // Return user data without password
            const { password: _, ...userWithoutPassword } = user;

            res.status(200).json({
                success: true,
                data: userWithoutPassword,
                message: 'User data retrieved successfully'
            } as ApiResponse<Omit<User, 'password'>>);
        } catch (error) {
            console.error('Get current user error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while retrieving user data'
            } as ApiResponse<null>);
        }
    }

    async refreshToken(req: Request, res: Response): Promise<void> {
        try {
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'No token provided'
                } as ApiResponse<null>);
                return;
            }

            const token = authHeader.substring(7);
            const decoded = this.getUserFromToken(token);
            
            if (!decoded) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'Invalid token'
                } as ApiResponse<null>);
                return;
            }

            // Find user
            const user = this.users.find(u => u.id === decoded.id);
            if (!user) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not found'
                } as ApiResponse<null>);
                return;
            }

            // Generate new token
            const newToken = this.generateToken(user);

            res.status(200).json({
                success: true,
                data: {
                    token: newToken
                },
                message: 'Token refreshed successfully'
            } as ApiResponse<{ token: string }>);
        } catch (error) {
            console.error('Refresh token error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while refreshing token'
            } as ApiResponse<null>);
        }
    }
}

export default AuthController;