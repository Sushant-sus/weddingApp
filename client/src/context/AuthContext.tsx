import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useReducer,
  type ReactNode,
} from 'react';
import { authApi } from '@/features/auth/auth.api';
import type { AuthUser } from '@/features/auth/auth.types';
import { tokenStore } from '@/lib/tokenStore';
import { setSessionExpiredHandler } from '@/lib/api';

interface AuthState {
  user: AuthUser | null;
  status: 'loading' | 'authenticated' | 'unauthenticated';
}

type Action =
  | { type: 'AUTHENTICATED'; user: AuthUser }
  | { type: 'UNAUTHENTICATED' };

function reducer(_state: AuthState, action: Action): AuthState {
  switch (action.type) {
    case 'AUTHENTICATED':
      return { user: action.user, status: 'authenticated' };
    case 'UNAUTHENTICATED':
      return { user: null, status: 'unauthenticated' };
  }
}

interface AuthContextValue extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  hasPermission: (perm: string) => boolean;
  hasRole: (...roles: string[]) => boolean;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, { user: null, status: 'loading' });

  // Rehydrate session on mount using the stored refresh token.
  useEffect(() => {
    let active = true;
    async function bootstrap() {
      const refreshToken = tokenStore.getRefreshToken();
      if (!refreshToken) {
        if (active) dispatch({ type: 'UNAUTHENTICATED' });
        return;
      }
      try {
        // No access token in memory after reload → /me returns 401 → the axios
        // interceptor transparently refreshes (using the stored refresh token)
        // and retries, so a single call rehydrates the session.
        const me = await authApi.me();
        if (active) dispatch({ type: 'AUTHENTICATED', user: me });
      } catch {
        tokenStore.clear();
        if (active) dispatch({ type: 'UNAUTHENTICATED' });
      }
    }
    bootstrap();
    return () => {
      active = false;
    };
  }, []);

  // When refresh fails irrecoverably, the api layer calls this.
  useEffect(() => {
    setSessionExpiredHandler(() => {
      tokenStore.clear();
      dispatch({ type: 'UNAUTHENTICATED' });
    });
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      ...state,
      login: async (email, password) => {
        const res = await authApi.login(email, password);
        tokenStore.setAccessToken(res.accessToken);
        tokenStore.setRefreshToken(res.refreshToken);
        dispatch({ type: 'AUTHENTICATED', user: res.user });
      },
      logout: async () => {
        try {
          await authApi.logout(tokenStore.getRefreshToken());
        } catch {
          /* ignore */
        }
        tokenStore.clear();
        dispatch({ type: 'UNAUTHENTICATED' });
      },
      hasPermission: (perm) =>
        state.user?.role === 'SUPERADMIN' || (state.user?.permissions ?? []).includes(perm),
      hasRole: (...roles) => !!state.user && roles.includes(state.user.role),
    }),
    [state],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
