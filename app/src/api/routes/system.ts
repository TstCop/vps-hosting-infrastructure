import { Router } from 'express';
import SystemController from '../controllers/SystemController';

const router = Router();
const systemController = new SystemController();

/**
 * @swagger
 * tags:
 *   name: System
 *   description: System management and health
 */

/**
 * @swagger
 * /api/system/health:
 *   get:
 *     summary: System health check
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: System health status
 */
router.get('/health', systemController.getHealth.bind(systemController));

/**
 * @swagger
 * /api/system/info:
 *   get:
 *     summary: System information
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: System information retrieved
 */
router.get('/info', systemController.getSystemInfo.bind(systemController));

export default router;