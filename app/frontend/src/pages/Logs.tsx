import {
    Clear as ClearIcon,
    Code as CodeIcon,
    FileDownload as DownloadIcon,
    Error as ErrorIcon,
    FilterList as FilterIcon,
    Info as InfoIcon,
    Refresh as RefreshIcon,
    Search as SearchIcon,
    Storage as StorageIcon,
    CheckCircle as SuccessIcon,
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
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    FormControl,
    IconButton,
    InputLabel,
    MenuItem,
    Pagination,
    Paper,
    Select,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    TextField,
    Typography
} from '@mui/material';
import React, { useState } from 'react';

interface LogEntry {
    id: string;
    timestamp: string;
    level: 'error' | 'warning' | 'info' | 'debug' | 'success';
    service: string;
    vm: string;
    component: string;
    message: string;
    details?: string;
    user?: string;
    ip?: string;
}

const mockLogs: LogEntry[] = [
    {
        id: '1',
        timestamp: '2024-12-19 15:30:25',
        level: 'error',
        service: 'nginx',
        vm: 'nginx-app-01',
        component: 'web-server',
        message: 'Failed to connect to upstream server',
        details: 'Connection timeout after 30 seconds',
        user: 'admin',
        ip: '192.168.1.100'
    },
    {
        id: '2',
        timestamp: '2024-12-19 15:28:15',
        level: 'warning',
        service: 'gitlab',
        vm: 'gitlab-01',
        component: 'runner',
        message: 'High memory usage detected',
        details: 'Memory usage: 85%',
        user: 'system',
        ip: '192.168.1.50'
    },
    {
        id: '3',
        timestamp: '2024-12-19 15:25:45',
        level: 'info',
        service: 'docker',
        vm: 'nginx-app-01',
        component: 'container',
        message: 'Container started successfully',
        details: 'Container ID: a1b2c3d4e5f6',
        user: 'deploy',
        ip: '192.168.1.100'
    },
    {
        id: '4',
        timestamp: '2024-12-19 15:22:30',
        level: 'success',
        service: 'backup',
        vm: 'gitlab-01',
        component: 'backup-service',
        message: 'Daily backup completed',
        details: 'Backup size: 2.5GB',
        user: 'backup-user'
    },
    {
        id: '5',
        timestamp: '2024-12-19 15:20:10',
        level: 'debug',
        service: 'kvm',
        vm: 'nginx-app-01',
        component: 'hypervisor',
        message: 'VM performance metrics collected',
        details: 'CPU: 15%, Memory: 45%, Disk: 20%'
    }
];

const Logs: React.FC = () => {
    const [logs] = useState<LogEntry[]>(mockLogs);
    const [filteredLogs, setFilteredLogs] = useState<LogEntry[]>(mockLogs);
    const [searchTerm, setSearchTerm] = useState('');
    const [levelFilter, setLevelFilter] = useState('all');
    const [serviceFilter, setServiceFilter] = useState('all');
    const [vmFilter, setVMFilter] = useState('all');
    const [dateFilter, setDateFilter] = useState('today');
    const [currentPage, setCurrentPage] = useState(1);
    const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null);
    const logsPerPage = 10;

    const filterLogs = () => {
        let filtered = logs;

        if (searchTerm) {
            filtered = filtered.filter(log =>
                log.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
                log.component.toLowerCase().includes(searchTerm.toLowerCase()) ||
                log.details?.toLowerCase().includes(searchTerm.toLowerCase())
            );
        }

        if (levelFilter !== 'all') {
            filtered = filtered.filter(log => log.level === levelFilter);
        }

        if (serviceFilter !== 'all') {
            filtered = filtered.filter(log => log.service === serviceFilter);
        }

        if (vmFilter !== 'all') {
            filtered = filtered.filter(log => log.vm === vmFilter);
        }

        setFilteredLogs(filtered);
        setCurrentPage(1);
    };

    React.useEffect(() => {
        filterLogs();
    }, [searchTerm, levelFilter, serviceFilter, vmFilter, dateFilter]);

    const clearFilters = () => {
        setSearchTerm('');
        setLevelFilter('all');
        setServiceFilter('all');
        setVMFilter('all');
        setDateFilter('today');
    };

    const handleExportLogs = () => {
        const csvContent = [
            ['Timestamp', 'Level', 'Service', 'VM', 'Component', 'Message', 'Details'],
            ...filteredLogs.map(log => [
                log.timestamp,
                log.level,
                log.service,
                log.vm,
                log.component,
                log.message,
                log.details || ''
            ])
        ].map(row => row.join(',')).join('\\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `logs-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
    };

    const getLevelColor = (level: string) => {
        switch (level) {
            case 'error': return 'error';
            case 'warning': return 'warning';
            case 'info': return 'info';
            case 'success': return 'success';
            case 'debug': return 'default';
            default: return 'default';
        }
    };

    const getLevelIcon = (level: string) => {
        switch (level) {
            case 'error': return <ErrorIcon />;
            case 'warning': return <WarningIcon />;
            case 'info': return <InfoIcon />;
            case 'success': return <SuccessIcon />;
            case 'debug': return <CodeIcon />;
            default: return <InfoIcon />;
        }
    };

    const totalPages = Math.ceil(filteredLogs.length / logsPerPage);
    const startIndex = (currentPage - 1) * logsPerPage;
    const paginatedLogs = filteredLogs.slice(startIndex, startIndex + logsPerPage);

    const services = Array.from(new Set(logs.map(log => log.service)));
    const vms = Array.from(new Set(logs.map(log => log.vm)));

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <TimelineIcon />
                Logs do Sistema
            </Typography>

            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <ErrorIcon color="error" />
                            <Box>
                                <Typography variant="h6" color="error">
                                    {logs.filter(log => log.level === 'error').length}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    Erros
                                </Typography>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <WarningIcon color="warning" />
                            <Box>
                                <Typography variant="h6" color="warning.main">
                                    {logs.filter(log => log.level === 'warning').length}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    Avisos
                                </Typography>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <InfoIcon color="info" />
                            <Box>
                                <Typography variant="h6" color="info.main">
                                    {logs.filter(log => log.level === 'info').length}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    Informações
                                </Typography>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>

                <Card sx={{ flex: 1, minWidth: 200 }}>
                    <CardContent>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <StorageIcon color="primary" />
                            <Box>
                                <Typography variant="h6" color="primary">
                                    {logs.length}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                    Total
                                </Typography>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>
            </Box>

            <Paper sx={{ p: 3, mb: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                    <FilterIcon />
                    <Typography variant="h6">Filtros</Typography>
                    <Button
                        variant="outlined"
                        size="small"
                        startIcon={<ClearIcon />}
                        onClick={clearFilters}
                    >
                        Limpar
                    </Button>
                    <Button
                        variant="outlined"
                        size="small"
                        startIcon={<RefreshIcon />}
                        onClick={() => window.location.reload()}
                    >
                        Atualizar
                    </Button>
                    <Button
                        variant="outlined"
                        size="small"
                        startIcon={<DownloadIcon />}
                        onClick={handleExportLogs}
                    >
                        Exportar
                    </Button>
                </Box>

                <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                    <TextField
                        label="Buscar logs..."
                        variant="outlined"
                        size="small"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        InputProps={{
                            startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                        }}
                        sx={{ minWidth: 300 }}
                    />

                    <FormControl size="small" sx={{ minWidth: 150 }}>
                        <InputLabel>Nível</InputLabel>
                        <Select
                            value={levelFilter}
                            label="Nível"
                            onChange={(e) => setLevelFilter(e.target.value)}
                        >
                            <MenuItem value="all">Todos</MenuItem>
                            <MenuItem value="error">Error</MenuItem>
                            <MenuItem value="warning">Warning</MenuItem>
                            <MenuItem value="info">Info</MenuItem>
                            <MenuItem value="success">Success</MenuItem>
                            <MenuItem value="debug">Debug</MenuItem>
                        </Select>
                    </FormControl>

                    <FormControl size="small" sx={{ minWidth: 150 }}>
                        <InputLabel>Serviço</InputLabel>
                        <Select
                            value={serviceFilter}
                            label="Serviço"
                            onChange={(e) => setServiceFilter(e.target.value)}
                        >
                            <MenuItem value="all">Todos</MenuItem>
                            {services.map(service => (
                                <MenuItem key={service} value={service}>{service}</MenuItem>
                            ))}
                        </Select>
                    </FormControl>

                    <FormControl size="small" sx={{ minWidth: 150 }}>
                        <InputLabel>VM</InputLabel>
                        <Select
                            value={vmFilter}
                            label="VM"
                            onChange={(e) => setVMFilter(e.target.value)}
                        >
                            <MenuItem value="all">Todas</MenuItem>
                            {vms.map(vm => (
                                <MenuItem key={vm} value={vm}>{vm}</MenuItem>
                            ))}
                        </Select>
                    </FormControl>

                    <FormControl size="small" sx={{ minWidth: 150 }}>
                        <InputLabel>Período</InputLabel>
                        <Select
                            value={dateFilter}
                            label="Período"
                            onChange={(e) => setDateFilter(e.target.value)}
                        >
                            <MenuItem value="today">Hoje</MenuItem>
                            <MenuItem value="week">Esta semana</MenuItem>
                            <MenuItem value="month">Este mês</MenuItem>
                            <MenuItem value="all">Todos</MenuItem>
                        </Select>
                    </FormControl>
                </Box>
            </Paper>

            <Paper>
                <TableContainer>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Timestamp</TableCell>
                                <TableCell>Nível</TableCell>
                                <TableCell>Serviço</TableCell>
                                <TableCell>VM</TableCell>
                                <TableCell>Componente</TableCell>
                                <TableCell>Mensagem</TableCell>
                                <TableCell>Ações</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {paginatedLogs.map((log) => (
                                <TableRow key={log.id} hover>
                                    <TableCell>{log.timestamp}</TableCell>
                                    <TableCell>
                                        <Chip
                                            icon={getLevelIcon(log.level)}
                                            label={log.level.toUpperCase()}
                                            color={getLevelColor(log.level) as any}
                                            size="small"
                                        />
                                    </TableCell>
                                    <TableCell>{log.service}</TableCell>
                                    <TableCell>{log.vm}</TableCell>
                                    <TableCell>{log.component}</TableCell>
                                    <TableCell sx={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                        {log.message}
                                    </TableCell>
                                    <TableCell>
                                        <IconButton
                                            size="small"
                                            onClick={() => setSelectedLog(log)}
                                        >
                                            <InfoIcon />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </TableContainer>

                <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="body2" color="text.secondary">
                        Mostrando {startIndex + 1}-{Math.min(startIndex + logsPerPage, filteredLogs.length)} de {filteredLogs.length} logs
                    </Typography>
                    <Pagination
                        count={totalPages}
                        page={currentPage}
                        onChange={(_, page) => setCurrentPage(page)}
                        color="primary"
                    />
                </Box>
            </Paper>

            <Dialog
                open={!!selectedLog}
                onClose={() => setSelectedLog(null)}
                maxWidth="md"
                fullWidth
            >
                <DialogTitle>
                    Detalhes do Log
                </DialogTitle>
                <DialogContent>
                    {selectedLog && (
                        <Box sx={{ mt: 2 }}>
                            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Timestamp
                                    </Typography>
                                    <Typography variant="body2" gutterBottom>{selectedLog.timestamp}</Typography>
                                </Box>

                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Nível
                                    </Typography>
                                    <Chip
                                        icon={getLevelIcon(selectedLog.level)}
                                        label={selectedLog.level.toUpperCase()}
                                        color={getLevelColor(selectedLog.level) as any}
                                        size="small"
                                    />
                                </Box>

                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Serviço
                                    </Typography>
                                    <Typography variant="body2" gutterBottom>{selectedLog.service}</Typography>
                                </Box>

                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        VM
                                    </Typography>
                                    <Typography variant="body2" gutterBottom>{selectedLog.vm}</Typography>
                                </Box>

                                <Box sx={{ flex: 1, minWidth: 200 }}>
                                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                        Componente
                                    </Typography>
                                    <Typography variant="body2">{selectedLog.component}</Typography>
                                </Box>

                                {selectedLog.user && (
                                    <Box sx={{ flex: 1, minWidth: 200 }}>
                                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                            Usuário
                                        </Typography>
                                        <Typography variant="body2" gutterBottom>{selectedLog.user}</Typography>
                                    </Box>
                                )}

                                {selectedLog.ip && (
                                    <Box sx={{ flex: 1, minWidth: 200 }}>
                                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                            IP
                                        </Typography>
                                        <Typography variant="body2" gutterBottom>{selectedLog.ip}</Typography>
                                    </Box>
                                )}
                            </Box>

                            <Box sx={{ mb: 2 }}>
                                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                    Mensagem
                                </Typography>
                                <Alert severity={selectedLog.level as any} sx={{ mb: 2 }}>
                                    <Typography variant="body2">{selectedLog.message}</Typography>
                                </Alert>

                                {selectedLog.details && (
                                    <Box>
                                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                            Detalhes
                                        </Typography>
                                        <Paper sx={{ p: 2, bgcolor: 'grey.50' }}>
                                            <Typography variant="body2">{selectedLog.details}</Typography>
                                        </Paper>
                                    </Box>
                                )}
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setSelectedLog(null)}>
                        Fechar
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default Logs;
