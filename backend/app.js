import express from "express"
import cors from "cors"

import healthRoutes from './routes/health.js'
import dashboardRoutes from './routes/dashboard.js'
import simulationsRoutes from './routes/simulations.js'

const app = express()

app.use(cors())
app.use(express.json())


app.use('/api', healthRoutes)
app.use('/api', dashboardRoutes)
app.use('/api', simulationsRoutes)

const port = 8000;

const server = app.listen(port, () => {
  console.log(`Server is listening on port ${port}...`);
  console.log("Server listening:", server.listening);
});

server.on("close", () => {
  console.log("HTTP server closed");
});

server.on("error", (error) => {
  console.error("HTTP server error:", error);
});

process.on("beforeExit", (code) => {
  console.log("Node is exiting with code:", code);
  console.log("Active resources:", process.getActiveResourcesInfo());
});