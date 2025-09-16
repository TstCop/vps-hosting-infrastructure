import { Router } from 'express';
import MonitoringController from '../controllers/MonitoringController';

const router = Router();
const monitoringController = new MonitoringController();

// RF04.1: Dashboard status
router.get('/dashboard', monitoringController.getDashboard.bind(monitoringController));

// RF04.3: Centralized logs
router.get('/logs', monitoringController.getLogs.bind(monitoringController));

// RF04.4: Alerts system
router.get('/alerts', monitoringController.getAlerts.bind(monitoringController));

// RF04.5: Performance reports
router.get('/reports/performance', monitoringController.getPerformanceReports.bind(monitoringController));

// RF04.6: Audit trail
router.get('/audit', monitoringController.getAuditTrail.bind(monitoringController));

export default router;