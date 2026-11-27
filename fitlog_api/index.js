const express = require('express')
const cors = require('cors')
const mysql = require('mysql2')
require('dotenv').config()

const fallbackNews = require('./news_fallback.json')
const app = express()

app.use(cors())
app.use(express.json())

function sendFallbackNews(res, reason) {
  return res.status(200).json({
    status: 'fallback',
    message: `${reason} Showing saved articles instead.`,
    total: fallbackNews.length,
    news: fallbackNews,
  })
}

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
  const apiKey = process.env.GNEWS_API_KEY

  if (!apiKey) {
    return sendFallbackNews(res, 'GNews API key is not configured.')
  }

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 10000)

  try {
    const url = new URL('https://gnews.io/api/v4/search')
    url.searchParams.set('q', 'fitness OR workout OR exercise')
    url.searchParams.set('lang', 'en')
    url.searchParams.set('max', '10')

    const response = await fetch(url, {
      method: 'GET',
      headers: { 'X-Api-Key': apiKey },
      signal: controller.signal,
    })

    if (response.status === 401 || response.status === 403) {
      return sendFallbackNews(res, 'GNews authentication failed.')
    }

    if (response.status === 429) {
      return sendFallbackNews(res, 'GNews request limit reached.')
    }

    if (!response.ok) {
      return sendFallbackNews(
        res,
        `GNews returned status ${response.status}.`
      )
    }

    let data
    try {
      data = await response.json()
    } catch {
      return sendFallbackNews(res, 'GNews returned invalid JSON.')
    }

    if (!data || !Array.isArray(data.articles)) {
      return sendFallbackNews(res, 'GNews returned an invalid response.')
    }

    const cleanArticles = data.articles
      .filter(
        (article) =>
          article &&
          typeof article.title === 'string' &&
          typeof article.url === 'string'
      )
      .slice(0, 10)
      .map((article) => ({
        title: article.title,
        summary:
          typeof article.description === 'string' ? article.description : '',
        link: article.url,
      }))

    if (cleanArticles.length === 0) {
      return sendFallbackNews(res, 'GNews returned no usable articles.')
    }

    return res.status(200).json({
      status: 'success',
      total: cleanArticles.length,
      news: cleanArticles,
    })
  } catch (error) {
    if (error.name === 'AbortError') {
      return sendFallbackNews(res, 'GNews request timed out.')
    }

    return sendFallbackNews(res, 'Could not connect to GNews.')
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
