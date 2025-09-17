import bodyParser from 'body-parser';
import cors from 'cors';
import express, { NextFunction, Request, Response } from 'express';
import { specs, swaggerUi } from '../config/swagger';
import { authMiddleware } from './middleware/auth';
import authRoutes from './routes/auth';
import clientRoutes from './routes/clients';
import configRoutes from './routes/configs';
import filesRoutes from './routes/files';
import logsRoutes from './routes/logs';
import monitoringRoutes from './routes/monitoring';
import searchRoutes from './routes/search';
import statsRoutes from './routes/stats';
import systemRoutes from './routes/system';
import templateRoutes from './routes/templates';
import vmRoutes from './routes/vms';

const app = express();

// CORS middleware - Allow all origins
app.use(cors({
    origin: '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Middleware
app.use(bodyParser.json());

// Only use auth middleware if not in test environment
if (process.env.NODE_ENV !== 'test') {
    app.use(authMiddleware);
}

// Swagger documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/configs', configRoutes);
app.use('/api/files', filesRoutes);
app.use('/api/logs', logsRoutes);
app.use('/api/monitoring', monitoringRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/system', systemRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/vms', vmRoutes);

// RF04.2: VM metrics route (specific to VMs)
import MonitoringController from './controllers/MonitoringController';
const monitoringController = new MonitoringController();
app.get('/api/vms/:id/metrics', monitoringController.getVMMetrics.bind(monitoringController));

/**
 * @swagger
 * /api/health:
 *   get:
 *     summary: Health check endpoint
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: API is running
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "VPS Hosting Infrastructure API is running"
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 version:
 *                   type: string
 *                   example: "1.0.0"
 */
// Health check endpoint
app.get('/api/health', (req: Request, res: Response) => {
    res.status(200).json({
        success: true,
        message: 'VPS Hosting Infrastructure API is running',
        timestamp: new Date(),
        version: '1.0.0'
    });
});

// Error handling
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: 'Something went wrong!'
    });
});

// 404 handler
app.use((req: Request, res: Response) => {
    res.status(404).json({
        success: false,
        error: 'Not found',
        message: `Route ${req.method} ${req.path} not found`
    });
});

// Start the server
const PORT = process.env.PORT || 4444;

if (process.env.NODE_ENV !== 'test') {
    app.listen(PORT, () => {
        console.log(`🚀 Server is running on port ${PORT}`);
        console.log(`📖 API Documentation available at http://localhost:${PORT}/api-docs`);
    });
}

export default app;
