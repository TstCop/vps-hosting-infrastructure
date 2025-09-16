import React, { useEffect, useState } from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  Computer as ComputerIcon,
  People as PeopleIcon,
  CloudQueue as CloudIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { apiService } from '../services/apiService';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

interface DashboardData {
  totalVMs: number;
  activeVMs: number;
  stoppedVMs: number;
  totalClients: number;
  activeClients: number;
  resourceUsage: {
    cpu: { used: number; total: number; unit: string };
    memory: { used: number; total: number; unit: string };
    storage: { used: number; total: number; unit: string };
  };
  recentActivity: Array<{
    id: string;
    type: string;
    message: string;
    timestamp: string;
  }>;
}

const StatCard: React.FC<{
  title: string;
  value: number;
  subtitle?: string;
  icon: React.ReactNode;
  color: string;
}> = ({ title, value, subtitle, icon, color }) => (
  <Card>
    <CardContent>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
        <Box sx={{ color, mr: 2 }}>{icon}</Box>
        <Typography variant="h6" component="div">
          {title}
        </Typography>
      </Box>
      <Typography variant="h4" component="div" sx={{ mb: 1 }}>
        {value}
      </Typography>
      {subtitle && (
        <Typography variant="body2" color="text.secondary">
          {subtitle}
        </Typography>
      )}
    </CardContent>
  </Card>
);

const ResourceUsageCard: React.FC<{
  title: string;
  used: number;
  total: number;
  unit: string;
}> = ({ title, used, total, unit }) => {
  const percentage = (used / total) * 100;
  return (
    <Card>
      <CardContent>
        <Typography variant="h6" component="div" sx={{ mb: 2 }}>
          {title}
        </Typography>
        <Box sx={{ mb: 2 }}>
          <Typography variant="h4" component="span">
            {used.toFixed(1)}
          </Typography>
          <Typography variant="body1" component="span" sx={{ ml: 1 }}>
            / {total} {unit}
          </Typography>
        </Box>
        <LinearProgress
          variant="determinate"
          value={percentage}
          sx={{ height: 8, borderRadius: 4 }}
        />
        <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
          {percentage.toFixed(1)}% used
        </Typography>
      </CardContent>
    </Card>
  );
};

const Dashboard: React.FC = () => {
  const [dashboardData, setDashboardData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const response = await apiService.get('/monitoring/dashboard');
        setDashboardData(response.data);
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  const chartData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      {
        label: 'CPU Usage %',
        data: [65, 59, 80, 81, 56, 55],
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
      },
      {
        label: 'Memory Usage %',
        data: [28, 48, 40, 19, 86, 27],
        borderColor: 'rgb(255, 99, 132)',
        backgroundColor: 'rgba(255, 99, 132, 0.2)',
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Resource Usage Over Time',
      },
    },
  };

  if (loading) {
    return (
      <Box sx={{ width: '100%' }}>
        <LinearProgress />
      </Box>
    );
  }

  if (!dashboardData) {
    return (
      <Typography variant="h6" color="error">
        Failed to load dashboard data
      </Typography>
    );
  }

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        Dashboard
      </Typography>

      {/* Statistics Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total VMs"
            value={dashboardData.totalVMs}
            subtitle={`${dashboardData.activeVMs} active, ${dashboardData.stoppedVMs} stopped`}
            icon={<ComputerIcon />}
            color="#1976d2"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Clients"
            value={dashboardData.totalClients}
            subtitle={`${dashboardData.activeClients} active`}
            icon={<PeopleIcon />}
            color="#2e7d32"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Templates"
            value={12}
            subtitle="Available templates"
            icon={<CloudIcon />}
            color="#ed6c02"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Alerts"
            value={3}
            subtitle="Active alerts"
            icon={<WarningIcon />}
            color="#d32f2f"
          />
        </Grid>
      </Grid>

      {/* Resource Usage */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <ResourceUsageCard
            title="CPU Usage"
            used={dashboardData.resourceUsage.cpu.used}
            total={dashboardData.resourceUsage.cpu.total}
            unit={dashboardData.resourceUsage.cpu.unit}
          />
        </Grid>
        <Grid item xs={12} md={4}>
          <ResourceUsageCard
            title="Memory Usage"
            used={dashboardData.resourceUsage.memory.used}
            total={dashboardData.resourceUsage.memory.total}
            unit={dashboardData.resourceUsage.memory.unit}
          />
        </Grid>
        <Grid item xs={12} md={4}>
          <ResourceUsageCard
            title="Storage Usage"
            used={dashboardData.resourceUsage.storage.used}
            total={dashboardData.resourceUsage.storage.total}
            unit={dashboardData.resourceUsage.storage.unit}
          />
        </Grid>
      </Grid>

      {/* Charts and Recent Activity */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Line data={chartData} options={chartOptions} />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" component="div" sx={{ mb: 2 }}>
                Recent Activity
              </Typography>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Action</TableCell>
                      <TableCell>Time</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {dashboardData.recentActivity.slice(0, 5).map((activity) => (
                      <TableRow key={activity.id}>
                        <TableCell>
                          <Typography variant="body2">
                            {activity.message}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="caption" color="text.secondary">
                            {new Date(activity.timestamp).toLocaleTimeString()}
                          </Typography>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;