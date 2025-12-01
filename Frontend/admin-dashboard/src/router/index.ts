import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/store/auth';
import LoginView from '@/views/LoginView.vue';
import DashboardLayout from '@/layouts/DashboardLayout.vue';
import UsersView from '@/views/UsersView.vue';
import ChildrenView from '@/views/ChildrenView.vue';
import CaregiversView from '@/views/CaregiversView.vue';
import PairingsView from '@/views/PairingsView.vue';
import AdminsView from '@/views/AdminsView.vue';

import OverviewView from '@/views/OverviewView.vue';

const routes = [
  { path: '/login', name: 'Login', component: LoginView },
  {
    path: '/dashboard',
    component: DashboardLayout,
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/dashboard/overview' },
      { path: 'overview', name: 'Overview', component: OverviewView },
      { path: 'users', name: 'Users', component: UsersView },
      { path: 'children', name: 'Children', component: ChildrenView },
      { path: 'caregivers', name: 'Caregivers', component: CaregiversView },
      { path: 'pairings', name: 'Pairings', component: PairingsView },
      { path: 'admins', name: 'Admins', component: AdminsView },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/login' },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login');
  } else {
    next();
  }
});

export default router;
