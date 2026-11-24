const express = require('express')
const cors = require('cors')
const mysql = require('mysql2')
require('dotenv').config()

const app = express()

app.use(cors())
app.use(express.json())

const connection = mysql.createPool({
  host: process.env.TIDB_HOST,
  port: Number(process.env.TIDB_PORT || 4000),
  user: process.env.TIDB_USER,
  password: process.env.TIDB_PASSWORD,
  database: process.env.TIDB_DATABASE,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  ssl: process.env.TIDB_ENABLE_SSL === 'true'
    ? { minVersion: 'TLSv1.2' }
    : null,
})

app.get('/', (req, res) => {
  res.send('Hello world!!')
})

app.get('/test-db', (req, res) => {
  connection.query(
    'SELECT 1 AS result',
    function (err, results) {
      if (err) {
        console.error('Database connection error:', err.message)
        res.status(500).send('Database connection failed')
      } else {
        res.status(200).json(results)
      }
    }
  )
})

app.get('/news', async (req, res) => {
  const binId = process.env.JSONBIN_BIN_ID
  const masterKey = process.env.JSONBIN_MASTER_KEY

  if (!binId || !masterKey) {
    return res.status(500).json({
      status: 'error',
      message: 'JSONBin configuration is missing',
    })
  }

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 10000)

  try {
    const response = await fetch(
      `https://api.jsonbin.io/v3/b/${encodeURIComponent(binId)}/latest`,
      {
        method: 'GET',
        headers: {
          'X-Master-Key': masterKey,
        },
        signal: controller.signal,
      }
    )

    if (response.status === 401 || response.status === 403) {
      return res.status(401).json({
        status: 'error',
        message: 'JSONBin authentication failed. Check the Master Key.',
      })
    }

    if (response.status === 404) {
      return res.status(404).json({
        status: 'error',
        message: 'JSONBin not found. Check the Bin ID.',
      })
    }

    if (!response.ok) {
      return res.status(502).json({
        status: 'error',
        message: 'JSONBin returned an unexpected response',
      })
    }

    let data
    try {
      data = await response.json()
    } catch (error) {
      return res.status(502).json({
        status: 'error',
        message: 'JSONBin returned an invalid JSON response',
      })
    }

    let articles

    if (data && Array.isArray(data.record)) {
      articles = data.record
    } else if (data && data.record && Array.isArray(data.record.news)) {
      articles = data.record.news
    } else if (Array.isArray(data && data.news)) {
      articles = data.news
    } else {
      return res.status(502).json({
        status: 'error',
        message: 'JSONBin response format is invalid',
      })
    }

    const cleanArticles = articles.slice(0, 10).map((article) => ({
      id: article.id,
      title: article.title,
      description: article.description,
      category: article.category,
      image: article.image,
      source: article.source,
      url: article.url,
      publishedAt: article.publishedAt,
    }))

    return res.status(200).json({
      status: 'success',
      total: cleanArticles.length,
      news: cleanArticles,
    })
  } catch (error) {
    if (error.name === 'AbortError') {
      return res.status(504).json({
        status: 'error',
        message: 'JSONBin connection timed out',
      })
    }

    return res.status(502).json({
      status: 'error',
      message: 'Could not connect to JSONBin',
    })
  } finally {
    clearTimeout(timeout)
  }
})

app.get('/workouts', (req, res) => {
  connection.query(
    'SELECT * FROM workouts',
    function (err, results) {
      if (err) {
        console.error('Error in GET /workouts:', err.message)
        res.status(500).send('Error retrieving workouts')
      } else {
        res.status(200).send(results)
      }
    }
  )
})

app.post('/workouts', (req, res) => {
  connection.query(
    'INSERT INTO `workouts` (`workout_day`, `exercise_name`, `weight`, `sets`, `reps`, `workout_date`) VALUES (?, ?, ?, ?, ?, ?)',
    [
      req.body.workout_day,
      req.body.exercise_name,
      req.body.weight,
      req.body.sets,
      req.body.reps,
      req.body.workout_date,
    ],
    function (err, results) {
      if (err) {
        console.error('Error in POST /workouts:', err.message)
        res.status(500).send('Error adding workout')
      } else {
        res.status(200).send('Workout added successfully')
      }
    }
  )
})

app.put('/workouts/:id', (req, res) => {
  const id = req.params.id

  connection.query(
    'UPDATE `workouts` SET `workout_day`=?, `exercise_name`=?, `weight`=?, `sets`=?, `reps`=?, `workout_date`=? WHERE id=?',
    [
      req.body.workout_day,
      req.body.exercise_name,
      req.body.weight,
      req.body.sets,
      req.body.reps,
      req.body.workout_date,
      id,
    ],
    function (err, results) {
      if (err) {
        console.error('Error in PUT /workouts/:id:', err.message)
        res.status(500).send('Error updating workout')
      } else if (results.affectedRows === 0) {
        res.status(404).send('Workout not found')
      } else {
        res.status(200).send('Workout updated successfully')
      }
    }
  )
})

app.delete('/workouts/:id', (req, res) => {
  const id = req.params.id

  connection.query(
    'DELETE FROM `workouts` WHERE id=?',
    [id],
    function (err, results) {
      if (err) {
        console.error('Error in DELETE /workouts/:id:', err.message)
        res.status(500).send('Error deleting workout')
      } else if (results.affectedRows === 0) {
        res.status(404).send('Workout not found')
      } else {
        res.status(200).send('Workout deleted successfully')
      }
    }
  )
})

app.listen(process.env.PORT || 3000, () => {
  console.log('CORS-enabled web server listening on port 3000')
})
