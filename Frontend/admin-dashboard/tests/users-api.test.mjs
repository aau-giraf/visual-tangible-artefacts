import assert from 'node:assert/strict';
import test, { after } from 'node:test';
import { fileURLToPath } from 'node:url';
import { createServer } from 'vite';

const dashboardRoot = fileURLToPath(new URL('..', import.meta.url));
let responseData;

globalThis.__apiClientMock = {
  get: async (path) => {
    assert.equal(path, '/Users');
    return { data: responseData };
  },
};

const server = await createServer({
  appType: 'custom',
  configFile: false,
  root: dashboardRoot,
  server: { middlewareMode: true },
  plugins: [
    {
      name: 'mock-api-client',
      resolveId(source, importer) {
        if (source === './axios' && importer?.endsWith('/src/api/users.ts')) {
          return '\0mock-api-client';
        }
      },
      load(id) {
        if (id === '\0mock-api-client') {
          return 'export default globalThis.__apiClientMock;';
        }
      },
    },
  ],
});

after(() => server.close());

const { getAllUsers } = await server.ssrLoadModule('/src/api/users.ts');

test('getAllUsers unwraps users from a paginated response', async () => {
  const users = [
    { id: 'user-1', name: 'Emil', username: 'emil', role: 0 },
    { id: 'user-2', name: 'Ada', username: 'ada', role: 2 },
  ];
  responseData = { items: users, totalCount: 2, skip: 0, take: 50 };

  assert.deepEqual(await getAllUsers(), users);
});

test('getAllUsers returns an empty array for an empty page', async () => {
  responseData = { items: [], totalCount: 0, skip: 0, take: 50 };

  assert.deepEqual(await getAllUsers(), []);
});
