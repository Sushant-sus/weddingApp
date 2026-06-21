import { createBrowserRouter } from 'react-router-dom';
import { AppLayout } from '@/components/layout/AppLayout';
import { DashboardPage } from '@/features/dashboard/DashboardPage';
import { GuestsPage } from '@/features/guests/GuestsPage';
import { GiftsPage } from '@/features/gifts/GiftsPage';
import { ItineraryPage } from '@/features/itinerary/ItineraryPage';
import { CostsPage } from '@/features/costs/CostsPage';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AppLayout />,
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'guests', element: <GuestsPage /> },
      { path: 'gifts', element: <GiftsPage /> },
      { path: 'itinerary', element: <ItineraryPage /> },
      { path: 'costs', element: <CostsPage /> },
    ],
  },
]);
