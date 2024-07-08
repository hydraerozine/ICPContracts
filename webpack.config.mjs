import path from 'path';
import { fileURLToPath } from 'url';
import webpack from 'webpack';
import HtmlWebpackPlugin from 'html-webpack-plugin';
import TerserPlugin from 'terser-webpack-plugin';
import CopyPlugin from 'copy-webpack-plugin';
import { createRequire } from 'module';
import Dotenv from 'dotenv-webpack';

const require = createRequire(import.meta.url);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const network = process.env.DFX_NETWORK || 'local';

// Define and initialize canister environment variables
async function initCanisterEnv() {
  let localCanisters, prodCanisters;
  try {
    localCanisters = await import('.dfx/local/canister_ids.json', { assert: { type: 'json' } });
  } catch (error) {
    console.log('No local canister_ids.json found. Continuing production');
  }
  try {
    prodCanisters = await import('./canister_ids.json', { assert: { type: 'json' } });
  } catch (error) {
    console.log('No production canister_ids.json found. Continuing with local');
  }

  const canisterConfig = network === 'local' ? localCanisters : prodCanisters;

  return Object.entries(canisterConfig?.default || {}).reduce((prev, current) => {
    const [canisterName, canisterDetails] = current;
    prev[canisterName.toUpperCase() + '_CANISTER_ID'] = canisterDetails[network];
    return prev;
  }, {});
}

const canisterEnvVariables = await initCanisterEnv();

const isDevelopment = process.env.NODE_ENV !== 'production';

// Ensure the environment variables are correctly initialized before using them
const internetIdentityCanisterId = process.env.INTERNET_IDENTITY_CANISTER_ID || canisterEnvVariables['INTERNET_IDENTITY_CANISTER_ID'] || 'br5f7-7uaaa-aaaaa-qaaca-cai';
const internetIdentityUrl = network === 'local'
  ? `http://${internetIdentityCanisterId}.localhost:4943/`
  : 'https://identity.ic0.app';

console.log('Internet Identity Canister ID:', internetIdentityCanisterId);
console.log('II URL:', internetIdentityUrl);

const frontendDirectory = 'RECEIPT_frontend';
const frontend_entry = path.join('src', frontendDirectory, 'assets', 'index.html');

export default {
  target: 'web',
  mode: isDevelopment ? 'development' : 'production',
  entry: {
    index: path.join(__dirname, frontend_entry).replace(/\.html$/, '.js'),
  },
  devtool: isDevelopment ? 'source-map' : false,
  optimization: {
    minimize: !isDevelopment,
    minimizer: [new TerserPlugin()],
  },
  resolve: {
    extensions: ['.js', '.ts', '.jsx', '.tsx'],
    fallback: {
      assert: require.resolve('assert'),
      buffer: require.resolve('buffer'),
      events: require.resolve('events'),
      stream: require.resolve('stream-browserify'),
      util: require.resolve('util'),
    },
  },
  output: {
    filename: 'index.js',
    path: path.join(__dirname, 'dist', frontendDirectory),
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env']
          }
        }
      }
    ]
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, frontend_entry),
      cache: false,
    }),
    new webpack.EnvironmentPlugin({
      NODE_ENV: 'development',
      II_URL: internetIdentityUrl,
      INTERNET_IDENTITY_CANISTER_ID: internetIdentityCanisterId,
      ...await canisterEnvVariables,
    }),
    new webpack.ProvidePlugin({
      Buffer: ['buffer', 'Buffer'],
      process: 'process/browser',
    }),
    new CopyPlugin({
      patterns: [
        {
          from: `src/${frontendDirectory}/assets/.ic-assets.json*`,
          to: '.ic-assets.json5',
          noErrorOnMissing: true,
        },
      ],
    }),
    new Dotenv(),
  ],
  devServer: {
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:4943',
        changeOrigin: true,
        pathRewrite: {
          '^/api': '/api',
        },
      },
    },
    static: path.resolve(__dirname, 'src', frontendDirectory, 'assets'),
    hot: true,
    watchFiles: [path.resolve(__dirname, 'src', frontendDirectory)],
    liveReload: true,
  },
};
