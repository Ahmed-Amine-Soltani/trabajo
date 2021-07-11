const express = require('express');
const redis = require('redis');
/* process to simulate server crashes */
//const process = require('process')

const app = express();
const client = redis.createClient({
    /* redis-server is the name of the container */
    host: 'redis-server',
    port: 6379
});

client.set('visits', 0);

app.get('/', (req, res) => {
/* process to simulate server crashes -> the server will crashe every time if someone visit /  */
/* just for test the restart policies */
/* to test the restart policies on-failure i can change the process.exit(0) to an other number */
 // process.exit(0);
  client.get('visits', (err, visits) => {
    res.send('Number of visits is ' + visits);
    client.set('visits', parseInt(visits) + 1);
  });
});

app.listen(8081, () => {
  console.log('Listening on port 8081');
});
