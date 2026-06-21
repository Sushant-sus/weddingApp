// Access token lives in memory (XSS-safer); refresh token in localStorage so
// the session survives reloads. AuthContext keeps these in sync.
const REFRESH_KEY = 'wedding.refreshToken';

let accessToken: string | null = null;

export const tokenStore = {
  getAccessToken: () => accessToken,
  setAccessToken: (token: string | null) => {
    accessToken = token;
  },
  getRefreshToken: () => localStorage.getItem(REFRESH_KEY),
  setRefreshToken: (token: string | null) => {
    if (token) localStorage.setItem(REFRESH_KEY, token);
    else localStorage.removeItem(REFRESH_KEY);
  },
  clear: () => {
    accessToken = null;
    localStorage.removeItem(REFRESH_KEY);
  },
};
