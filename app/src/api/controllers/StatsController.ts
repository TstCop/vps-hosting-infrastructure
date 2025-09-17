import { Request, Response } from 'express';
import { ApiResponse } from '../../types';

interface OverviewStats {
    clients: {
        total: number;
        active: number;
        new_this_month: number;
    };
    vms: {
        total: number;
        running: number;
        stopped: number;
        created_this_month: number;
    };
    resources: {
        cpu_utilization: number;
        memory_utilization: number;
        storage_utilization: number;
    };
}

class StatsController {
    async getOverview(req: Request, res: Response): Promise<void> {
        try {
            // Mock statistics - in production this would be calculated from real data
            const stats: OverviewStats = {
                clients: {
                    total: 50,
                    active: 45,
                    new_this_month: 5
                },
                vms: {
                    total: 150,
                    running: 142,
                    stopped: 8,
                    created_this_month: 20
                },
                resources: {
                    cpu_utilization: 65.4,
                    memory_utilization: 78.2,
                    storage_utilization: 45.8
                }
            };

            res.status(200).json({
                success: true,
                data: stats,
                message: 'Overview statistics retrieved successfully'
            } as ApiResponse<OverviewStats>);
        } catch (error) {
            console.error('Get overview stats error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong while retrieving statistics'
            } as ApiResponse<null>);
        }
    }
}

export default StatsController;