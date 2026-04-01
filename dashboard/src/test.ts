import 'zone.js/testing';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting,
} from '@angular/platform-browser-dynamic/testing';
import {
  Chart,
  LinearScale,
  LogarithmicScale,
  CategoryScale,
  BarElement,
  BarController,
  LineElement,
  LineController,
  PointElement,
  ArcElement,
  DoughnutController,
  PieController,
  RadarController,
  RadialLinearScale,
  ScatterController,
  BubbleController,
  Legend,
  Title,
  Tooltip,
  Filler,
} from 'chart.js';

// Register all Chart.js components globally for Angular tests
Chart.register(
  LinearScale,
  LogarithmicScale,
  CategoryScale,
  BarElement,
  BarController,
  LineElement,
  LineController,
  PointElement,
  ArcElement,
  DoughnutController,
  PieController,
  RadarController,
  RadialLinearScale,
  ScatterController,
  BubbleController,
  Legend,
  Title,
  Tooltip,
  Filler,
);

getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting(),
);
