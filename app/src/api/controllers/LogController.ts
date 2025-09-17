import { Request, Response } from 'express';
import { ApiResponse } from '../../types';

interface LogEntry {
    id: string;
    timestamp: string;
    level: 'error' | 'warning' | 'info' | 'debug';
    service: string;
    vm: string;
    component: string;
    message: string;
    details?: string;
    user?: string;
    ip?: string;
    metadata?: Record<string, any>;
}

interface LogQueryParams {
    level?: string;
    service?: string;
    vm?: string;
    component?: string;
    search?: string;
    startDate?: string;
    endDate?: string;
    page?: string;
    limit?: string;
}

class LogController {
    // Mock logs database - in production this would be from a real database
    private logs: LogEntry[] = [
        {
            id: 'log-1',
            timestamp: '2024-12-19T15:30:25Z',
            level: 'error',
            service: 'nginx',
            vm: 'nginx-app-01',
            component: 'web-server',
            message: 'Failed to connect to upstream server',
            details: 'Connection timeout after 30 seconds',
            user: 'admin',
            ip: '192.168.1.100',
            metadata: {
                requestId: 'req-123',
                userAgent: 'Mozilla/5.0...'
            }
        },
        {
            id: 'log-2',
            timestamp: '2024-12-19T15:25:15Z',
            level: 'warning',
            service: 'gitlab',
            vm: 'gitlab-runner-02',
            component: 'ci-cd',
            message: 'Build pipeline took longer than expected',
            details: 'Pipeline duration: 45 minutes',
            user: 'system',
            ip: '192.168.1.200'
        },
        {
            id: 'log-3',
            timestamp: '2024-12-19T15:20:10Z',
            level: 'info',
            service: 'docker',
            vm: 'docker-host-01',
            component: 'container-runtime',
            message: 'Container nginx-web started successfully',
            user: 'admin',
            ip: '192.168.1.100'
        },
        {
            id: 'log-4',
            timestamp: '2024-12-19T15:15:05Z',
            level: 'debug',
            service: 'kvm',
            vm: 'kvm-host-01',
            component: 'virtualization',
            message: 'VM resource allocation completed',
            details: 'Allocated 2 CPU cores, 4GB RAM',
            user: 'system'
        },
        {
            id: 'log-5',
            timestamp: '2024-12-19T15:10:00Z',
            level: 'error',
            service: 'nginx',
            vm: 'nginx-app-02',
            component: 'web-server',
            message: '502 Bad Gateway error',
            details: 'Upstream server not responding',
            user: 'guest',
            ip: '203.0.113.45'
        }
    ];

    async getLogs(req: Request, res: Response): Promise<void> {
        try {
            const {
                level,
                service,
                vm,
                component,
                search,
                startDate,
                endDate,
                page = '1',
                limit = '50'
            }: LogQueryParams = req.query;

            let filteredLogs = [...this.logs];

            // Apply filters
            if (level) {
                filteredLogs = filteredLogs.filter(log => log.level === level);
            }

            if (service) {
                filteredLogs = filteredLogs.filter(log => log.service.toLowerCase().includes(service.toLowerCase()));
            }

            if (vm) {
                filteredLogs = filteredLogs.filter(log => log.vm.toLowerCase().includes(vm.toLowerCase()));
            }

            if (component) {
                filteredLogs = filteredLogs.filter(log => log.component.toLowerCase().includes(component.toLowerCase()));
            }

            if (search) {
                filteredLogs = filteredLogs.filter(log => 
                    log.message.toLowerCase().includes(search.toLowerCase()) ||
                    (log.details && log.details.toLowerCase().includes(search.toLowerCase()))
                );
            }

            if (startDate) {
                filteredLogs = filteredLogs.filter(log => new Date(log.timestamp) >= new Date(startDate));
            }

            if (endDate) {
                filteredLogs = filteredLogs.filter(log => new Date(log.timestamp) <= new Date(endDate));
            }

            // Sort by timestamp (newest first)
            filteredLogs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

            // Pagination
            const pageNum = parseInt(page);
            const limitNum = parseInt(limit);
            const total = filteredLogs.length;
            const totalPages = Math.ceil(total / limitNum);
            const startIndex = (pageNum - 1) * limitNum;
            const endIndex = startIndex + limitNum;
            const paginatedLogs = filteredLogs.slice(startIndex, endIndex);

            res.status(200).json({
                success: true,
                data: paginatedLogs,
                pagination: {
                    page: pageNum,
                    limit: limitNum,
                    total,
                    totalPages
                },
                message: 'Logs retrieved successfully'
            } as ApiResponse<LogEntry[]>);
        } catch (error) {
            console.error('Get logs error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while retrieving logs'
            } as ApiResponse<null>);
        }
    }

    async getLogById(req: Request, res: Response): Promise<void> {
        try {
            const { id } = req.params;

            const log = this.logs.find(l => l.id === id);
            if (!log) {
                res.status(404).json({
                    success: false,
                    error: 'Not found',
                    message: 'Log not found'
                } as ApiResponse<null>);
                return;
            }

            res.status(200).json({
                success: true,
                data: log,
                message: 'Log retrieved successfully'
            } as ApiResponse<LogEntry>);
        } catch (error) {
            console.error('Get log by ID error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while retrieving log'
            } as ApiResponse<null>);
        }
    }

    async exportLogs(req: Request, res: Response): Promise<void> {
        try {
            const { level, service, startDate, endDate }: LogQueryParams = req.query;

            let filteredLogs = [...this.logs];

            // Apply filters (same as getLogs)
            if (level) {
                filteredLogs = filteredLogs.filter(log => log.level === level);
            }

            if (service) {
                filteredLogs = filteredLogs.filter(log => log.service.toLowerCase().includes(service.toLowerCase()));
            }

            if (startDate) {
                filteredLogs = filteredLogs.filter(log => new Date(log.timestamp) >= new Date(startDate));
            }

            if (endDate) {
                filteredLogs = filteredLogs.filter(log => new Date(log.timestamp) <= new Date(endDate));
            }

            // Sort by timestamp
            filteredLogs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

            // Generate CSV
            const csvHeaders = 'Timestamp,Level,Service,VM,Component,Message,Details,User,IP\n';
            const csvRows = filteredLogs.map(log => {
                const escapeCsv = (str: string | undefined) => {
                    if (!str) return '';
                    return `"${str.replace(/"/g, '""')}"`;
                };

                return [
                    log.timestamp,
                    log.level,
                    escapeCsv(log.service),
                    escapeCsv(log.vm),
                    escapeCsv(log.component),
                    escapeCsv(log.message),
                    escapeCsv(log.details),
                    escapeCsv(log.user),
                    escapeCsv(log.ip)
                ].join(',');
            }).join('\n');

            const csvContent = csvHeaders + csvRows;

            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=logs-export.csv');
            res.status(200).send(csvContent);
        } catch (error) {
            console.error('Export logs error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while exporting logs'
            } as ApiResponse<null>);
        }
    }

    async getLogStats(req: Request, res: Response): Promise<void> {
        try {
            const total = this.logs.length;

            // Count by level
            const byLevel = {
                error: this.logs.filter(log => log.level === 'error').length,
                warning: this.logs.filter(log => log.level === 'warning').length,
                info: this.logs.filter(log => log.level === 'info').length,
                debug: this.logs.filter(log => log.level === 'debug').length
            };

            // Count by service
            const serviceStats: Record<string, number> = {};
            this.logs.forEach(log => {
                serviceStats[log.service] = (serviceStats[log.service] || 0) + 1;
            });

            // Count by VM
            const vmStats: Record<string, number> = {};
            this.logs.forEach(log => {
                vmStats[log.vm] = (vmStats[log.vm] || 0) + 1;
            });

            res.status(200).json({
                success: true,
                data: {
                    total,
                    byLevel,
                    byService: serviceStats,
                    byVM: vmStats
                },
                message: 'Log statistics retrieved successfully'
            } as ApiResponse<{
                total: number;
                byLevel: Record<string, number>;
                byService: Record<string, number>;
                byVM: Record<string, number>;
            }>);
        } catch (error) {
            console.error('Get log stats error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while retrieving log statistics'
            } as ApiResponse<null>);
        }
    }
}

export default LogController;