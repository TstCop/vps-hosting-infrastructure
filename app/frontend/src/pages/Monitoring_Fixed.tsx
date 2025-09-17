import {
    Computer as ComputerIcon,
    Error as ErrorIcon,
    Info as InfoIcon,
    Refresh as RefreshIcon,
    Timeline as TimelineIcon,
    Warning as WarningIcon
} from '@mui/icons-material';
import {
    Alert,
    Box,
    Button,
    Card,
    CardContent,
    Chip,
    IconButton,
    LinearProgress,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography
} from '@mui/material';
import React, { useState } from 'react';

interface SystemMetrics {
    cpuUsage: number;
    memoryUsage: number;
    diskUsage: number;
    networkIn: number;
    networkOut: number;
}

interface Alert {
    id: string;
    type: 'error' | 'warning' | 'info';
    title: string;
    message: string;
    timestamp: string;
}

interface VMStatus {
    id: string;
    name: string;
    status: 'running' | 'stopped' | 'warning';
    cpu: number;
    memory: number;
    disk: number;
}

const mockSystemMetrics: SystemMetrics = {
    cpuUsage: 65,
    memoryUsage: 78,
    diskUsage: 45,
    networkIn: 125,
    networkOut: 89
};

const mockAlerts: Alert[] = [
    {
        id: '1',
        type: 'error',
        title: 'VM nginx-app-01 Down',
        message: 'VM parou de responder há 5 minutos',
        timestamp: '2024-12-19 15:30:00'
    },
    {
        id: '2',
        type: 'warning',
        title: 'Alto uso de memória',
        message: 'GitLab-01 usando 85% da memória',
        timestamp: '2024-12-19 15:25:00'
    }
];

const mockVMStatuses: VMStatus[] = [
    { id: '1', name: 'nginx-app-01', status: 'running', cpu: 15, memory: 45, disk: 30 },
    { id: '2', name: 'gitlab-01', status: 'warning', cpu: 78, memory: 85, disk: 55 },
    { id: '3', name: 'db-server-01', status: 'stopped', cpu: 0, memory: 0, disk: 25 }
];

const Monitoring: React.FC = () => {
    const [systemMetrics] = useState<SystemMetrics>(mockSystemMetrics);
    const [alerts] = useState<Alert[]>(mockAlerts);
    const [vmStatuses] = useState<VMStatus[]>(mockVMStatuses);

    const getAlertIcon = (type: string) => {
        switch (type) {
            case 'error': return <ErrorIcon />;
            case 'warning': return <WarningIcon />;
            case 'info': return <InfoIcon />;
            default: return <InfoIcon />;
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'running': return 'success';
            case 'stopped': return 'error';
            case 'warning': return 'warning';
            default: return 'default';
        }
    };

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h4" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <TimelineIcon />
                    Monitoramento
                </Typography>
                <Button variant="outlined" startIcon={<RefreshIcon />}>
                    Atualizar
                </Button>
            </Box>

            {/* System Overview */}
            <Box sx={{ display: 'flex', gap: 2, mb: 4, flexWrap: 'wrap' }}>
                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Typography variant="h6" color="primary">
                            CPU Global
                        </Typography>
                        <Typography variant="h4" gutterBottom>
                            {systemMetrics.cpuUsage}%
                        </Typography>
                        <LinearProgress
                            variant="determinate"
                            value={systemMetrics.cpuUsage}
                            sx={{ height: 8, borderRadius: 4 }}
                        />
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Typography variant="h6" color="secondary">
                            Memória Global
                        </Typography>
                        <Typography variant="h4" gutterBottom>
                            {systemMetrics.memoryUsage}%
                        </Typography>
                        <LinearProgress
                            variant="determinate"
                            value={systemMetrics.memoryUsage}
                            sx={{ height: 8, borderRadius: 4 }}
                        />
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Typography variant="h6" color="info.main">
                            Disco Global
                        </Typography>
                        <Typography variant="h4" gutterBottom>
                            {systemMetrics.diskUsage}%
                        </Typography>
                        <LinearProgress
                            variant="determinate"
                            value={systemMetrics.diskUsage}
                            sx={{ height: 8, borderRadius: 4 }}
                        />
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Typography variant="h6" color="warning.main">
                            Rede (MB/s)
                        </Typography>
                        <Typography variant="body1">
                            ↓ {systemMetrics.networkIn} MB/s
                        </Typography>
                        <Typography variant="body1">
                            ↑ {systemMetrics.networkOut} MB/s
                        </Typography>
                    </CardContent>
                </Card>
            </Box>

            <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
                {/* Alerts */}
                <Card sx={{ flex: 2, minWidth: 400 }}>
                    <CardContent>
                        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <WarningIcon />
                            Alertas Recentes
                        </Typography>

                        {alerts.length === 0 ? (
                            <Alert severity="success">
                                Nenhum alerta ativo no momento
                            </Alert>
                        ) : (
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                {alerts.map((alert) => (
                                    <Alert
                                        key={alert.id}
                                        severity={alert.type as any}
                                        icon={getAlertIcon(alert.type)}
                                        action={
                                            <IconButton size="small">
                                                <InfoIcon />
                                            </IconButton>
                                        }
                                    >
                                        <Typography variant="subtitle2">{alert.title}</Typography>
                                        <Typography variant="body2">{alert.message}</Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            {alert.timestamp}
                                        </Typography>
                                    </Alert>
                                ))}
                            </Box>
                        )}
                    </CardContent>
                </Card>

                {/* VM Status */}
                <Card sx={{ flex: 1, minWidth: 300 }}>
                    <CardContent>
                        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <ComputerIcon />
                            Status das VMs
                        </Typography>

                        <Paper>
                            <TableContainer>
                                <Table size="small">
                                    <TableHead>
                                        <TableRow>
                                            <TableCell>VM</TableCell>
                                            <TableCell>Status</TableCell>
                                            <TableCell>CPU</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {vmStatuses.map((vm) => (
                                            <TableRow key={vm.id}>
                                                <TableCell>{vm.name}</TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={vm.status}
                                                        color={getStatusColor(vm.status) as any}
                                                        size="small"
                                                    />
                                                </TableCell>
                                                <TableCell>{vm.cpu}%</TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </TableContainer>
                        </Paper>
                    </CardContent>
                </Card>
            </Box>
        </Box>
    );
};

export default Monitoring;
