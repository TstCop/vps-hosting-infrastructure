import { Request, Response } from 'express';
import { ApiResponse } from '../../types';

interface SystemHealth {
    status: 'healthy' | 'degraded' | 'unhealthy';
    timestamp: string;
    services: {
        database: 'healthy' | 'degraded' | 'unhealthy';
        vagrant: 'healthy' | 'degraded' | 'unhealthy';
        kvm: 'healthy' | 'degraded' | 'unhealthy';
    };
    uptime: number;
    memory: {
        used: number;
        total: number;
        percentage: number;
    };
    cpu: {
        usage: number;
        load: number[];
    };
}

interface SystemInfo {
    version: string;
    environment: string;
    node_version: string;
    platform: string;
    architecture: string;
    memory_total: number;
    cpu_count: number;
    uptime: number;
}

class SystemController {
    async getHealth(req: Request, res: Response): Promise<void> {
        try {
            // Mock health data - in production this would check actual services
            const memoryUsage = process.memoryUsage();
            const totalMemory = memoryUsage.heapTotal + memoryUsage.external;
            const usedMemory = memoryUsage.heapUsed;

            const health: SystemHealth = {
                status: 'healthy',
                timestamp: new Date().toISOString(),
                services: {
                    database: 'healthy',
                    vagrant: 'healthy',
                    kvm: 'healthy'
                },
                uptime: process.uptime(),
                memory: {
                    used: Math.round(usedMemory / 1024 / 1024), // MB
                    total: Math.round(totalMemory / 1024 / 1024), // MB
                    percentage: Math.round((usedMemory / totalMemory) * 100)
                },
                cpu: {
                    usage: Math.random() * 100, // Mock CPU usage
                    load: [0.5, 0.7, 0.3] // Mock load averages
                }
            };

            // Determine overall health based on services
            const unhealthyServices = Object.values(health.services).filter(status => status === 'unhealthy').length;
            const degradedServices = Object.values(health.services).filter(status => status === 'degraded').length;

            if (unhealthyServices > 0) {
                health.status = 'unhealthy';
            } else if (degradedServices > 0) {
                health.status = 'degraded';
            }

            const statusCode = health.status === 'healthy' ? 200 : 503;

            res.status(statusCode).json({
                success: health.status === 'healthy',
                data: health,
                message: `System is ${health.status}`
            } as ApiResponse<SystemHealth>);
        } catch (error) {
            console.error('Get system health error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while checking system health'
            } as ApiResponse<null>);
        }
    }

    async getSystemInfo(req: Request, res: Response): Promise<void> {
        try {
            const systemInfo: SystemInfo = {
                version: process.env.npm_package_version || '1.0.0',
                environment: process.env.NODE_ENV || 'development',
                node_version: process.version,
                platform: process.platform,
                architecture: process.arch,
                memory_total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024), // MB
                cpu_count: require('os').cpus().length,
                uptime: process.uptime()
            };

            res.status(200).json({
                success: true,
                data: systemInfo,
                message: 'System information retrieved successfully'
            } as ApiResponse<SystemInfo>);
        } catch (error) {
            console.error('Get system info error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while retrieving system information'
            } as ApiResponse<null>);
        }
    }
}

export default SystemController;