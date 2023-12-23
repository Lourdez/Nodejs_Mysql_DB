var express = require('express');
var mysql = require('mysql');
var path = require('path');

var bodyParser = require('body-parser');
var app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

var pool = mysql.createPool({
    connectionLimit: 10,
    host: 'database-1.cuohe0bgnbcx.us-west-2.rds.amazonaws.com',
    user: 'admin',
    password: 'admin123',
    database: 'db'
});

app.get('/', function(req, res) {
    res.sendFile(path.join(__dirname + '/index.html'));
});

app.post('/addToDB', function(req, res) {
    pool.getConnection((err, connection) => {
        if (err) {
            console.error('Error getting connection from pool:', err);
            res.sendStatus(500);
            return;
        }

        let sql = "INSERT INTO people (name, email) VALUES (?, ?)";
        let values = [req.body.username, req.body.email];

        connection.query(sql, values, (err, results) => {
            connection.release(); // Release the connection back to the pool

            if (err) {
                console.error('Error inserting data into MySQL:', err);
                res.sendStatus(500);
            } else {
                console.log('Data inserted into MySQL');
                res.redirect('/getdata');
            }
        });
    });
});

app.get('/getdata', function(req, res) {
    pool.getConnection((err, connection) => {
        if (err) {
            console.error('Error getting connection from pool:', err);
            res.sendStatus(500);
            return;
        }

        let sql = "SELECT * FROM people";
        connection.query(sql, (err, results) => {
            connection.release(); // Release the connection back to the pool

            if (err) {
                console.error('Error retrieving data from MySQL:', err);
                res.sendStatus(500);
            } else {
                res.send(results);
            }
        });
    });
});

app.listen('3000', () => {
    console.log('Server listening on port 3000');
});

