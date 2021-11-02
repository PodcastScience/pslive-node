const path = require('path');
module.exports = {
    entry: './src/client.coffee',
    mode: 'none',
    output: {
      filename: 'client.js',
      path: path.resolve(__dirname, 'dist/js/'),
    },
    module: {
      rules: [
        {
          loader: "coffee-loader",
        },
      ],
    },
  };