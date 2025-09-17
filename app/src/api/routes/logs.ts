import { Router } from 'express';
import LogController from '../controllers/LogController';

const router = Router();
const logController = new LogController();

/**
 * @swagger
 * tags:
 *   name: Logs
 *   description: Log management and monitoring
 */

/**
 * @swagger
 * /api/logs/export:
 *   get:
 *     summary: Export logs as CSV
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: level
 *         schema:
 *           type: string
 *         description: Filter by log level
 *       - in: query
 *         name: service
 *         schema:
 *           type: string
 *         description: Filter by service name
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Start date filter
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: End date filter
 *     responses:
 *       200:
 *         description: CSV file
 *         content:
 *           text/csv:
 *             schema:
 *               type: string
 *               format: binary
 */
router.get('/export', logController.exportLogs.bind(logController));

/**
 * @swagger
 * /api/logs/stats:
 *   get:
 *     summary: Get log statistics
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Log statistics retrieved
 */
router.get('/stats', logController.getLogStats.bind(logController));

/**
 * @swagger
 * /api/logs:
 *   get:
 *     summary: Get logs with filtering
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: level
 *         schema:
 *           type: string
 *           enum: [error, warning, info, debug]
 *         description: Filter by log level
 *       - in: query
 *         name: service
 *         schema:
 *           type: string
 *         description: Filter by service name
 *       - in: query
 *         name: vm
 *         schema:
 *           type: string
 *         description: Filter by VM name
 *       - in: query
 *         name: component
 *         schema:
 *           type: string
 *         description: Filter by component
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in log messages
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Start date filter
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: End date filter
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *         description: Items per page
 *     responses:
 *       200:
 *         description: Logs retrieved successfully
 *       400:
 *         description: Invalid parameters
 */
router.get('/', logController.getLogs.bind(logController));

/**
 * @swagger
 * /api/logs/{id}:
 *   get:
 *     summary: Get specific log details
 *     tags: [Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Log ID
 *     responses:
 *       200:
 *         description: Log details retrieved
 *       404:
 *         description: Log not found
 */
router.get('/:id', logController.getLogById.bind(logController));

export default router;