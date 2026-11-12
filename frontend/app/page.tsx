"use client";
import { useState, useEffect } from "react";

import Image from "next/image";
import { MdOutlineDashboard } from "react-icons/md";
import { LiaCubesSolid } from "react-icons/lia";
import { FaCodeBranch } from "react-icons/fa";
import { IoRocketOutline } from "react-icons/io5";
import { FaRegFileLines } from "react-icons/fa6";
import { BsCpu } from "react-icons/bs";
import { RiFlashlightLine } from "react-icons/ri";
import { MdOutlineCancel } from "react-icons/md";
import { BsMemory } from "react-icons/bs";
import { LuShieldCheck } from "react-icons/lu";
import { LuShieldAlert } from "react-icons/lu";

import { TbServer } from "react-icons/tb";
import { BiCube } from "react-icons/bi";
import { RiNetworkLine } from "react-icons/ri";

import { MdOutlineCheckCircle } from "react-icons/md";

import OverviewCard from "./components/OverviewCard";
import Monitor from "./components/Monitor";
import Pods from "./components/Pods";
import Branches from "./components/Branches";
import Events from "./components/Events";

const formatPercent = (value: number) => `${value.toFixed(1)}%`;

export default function Home() {
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [simulating, setSimulating] = useState(false);

  // Worker Nodes
  const nodesReady = data?.kubernetes?.nodes?.ready;
  const nodesTotal = data?.kubernetes?.nodes?.total;
  const workerNodes =
    nodesReady != null && nodesTotal != null
      ? `${nodesReady} / ${nodesTotal}`
      : "N/A";

  // Pods
  const podsReady = data?.kubernetes?.pods?.ready;
  const podsTotal = data?.kubernetes?.pods?.total;
  const runningPods =
    podsReady != null && podsTotal != null
      ? `${podsReady} / ${podsTotal}`
      : "N/A";

  // function to determine the status of a metric based on thresholds
  const getMetricStatus = (
    value: number | null | undefined,
    warning: number,
    danger: number,
  ): "green" | "yellow" | "red" | "gray" => {
    if (value == null || !Number.isFinite(value)) return "gray";

    if (value >= danger) return "red";
    if (value >= warning) return "yellow";

    return "green";
  };

  // CPU Usage (%)
  const nodeCPU = data?.cloudwatch?.nodeCPU?.value;

  const cpuUsage =
    nodeCPU != null && Number.isFinite(nodeCPU)
      ? `${nodeCPU.toFixed(1)}%`
      : "N/A";

  const cpuStatus = getMetricStatus(nodeCPU, 30, 60);

  // Node Memory Usage (%)
  const nodeMemory = data?.cloudwatch?.nodeMemory?.value;
  const memoryUsage =
    nodeMemory != null && Number.isFinite(nodeMemory)
      ? `${nodeMemory.toFixed(1)}%`
      : "N/A";

  const memoryStatus = getMetricStatus(nodeMemory, 60, 80);

  // Deployment Health
  const deployments = data?.kubernetes?.deployments;

  const totalDeployments = deployments?.length ?? 0;

  const readyDeployments =
    deployments?.filter(
      (deployment: { desired: number; ready: number; available: number }) =>
        deployment.desired > 0 &&
        deployment.ready === deployment.desired &&
        deployment.available === deployment.desired,
    ).length ?? 0;

  const deploymentHealth =
    totalDeployments > 0 ? `${readyDeployments} / ${totalDeployments}` : "N/A";

  const deploymentStatus =
    totalDeployments === 0
      ? "gray"
      : readyDeployments === totalDeployments
        ? "green"
        : "red";

// Determine if all systems are healthy
  const allHealthy =
  nodesTotal > 0 &&
  nodesReady === nodesTotal &&
  podsTotal > 0 &&
  podsReady === podsTotal &&
  totalDeployments > 0 &&
  readyDeployments === totalDeployments;      
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch("/api/dashboard", {
          cache: "no-store",
        });

        if (!response.ok) {
          throw new Error(`Failed to retrieve data: ${response.status}`);
        }

        const result = await response.json();

        setData(result);
        setError("");
      } catch (error) {
        setError(error instanceof Error ? error.message : String(error));
      }
    };

    fetchData();

    const interval = setInterval(fetchData, 1000);

    return () => clearInterval(interval);
  }, []);

  console.log(data);

  const simulateCPU = async () => {
    setSimulating(true);

    try {
      const response = await fetch("/api/simulations/cpu-spike", {
        method: "POST",
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || result.message);
      }

      console.log(result.message);
    } catch (error) {
      console.error("CPU simulation failed:", error);
    } finally {
      setSimulating(false);
    }
  };

  const [crashing, setCrashing] = useState(false);

  const simulatePodCrash = async () => {
    setCrashing(true);

    try {
      const response = await fetch("/api/simulations/pod-crash", {
        method: "POST",
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || "Failed to simulate Pod crash");
      }

      console.log(result.message);
      console.log("Deleted Pod:", result.deletedPod);
    } catch (error) {
      console.error("Pod crash simulation failed:", error);
    } finally {
      setCrashing(false);
    }
  };

  return (
    <div className="flex-center bg-gray-200 h-full">
      <div className="w-225 h-auto rounded-3xl bg-[#F3F6F8] my-10 border border-gray-300 shadow-lg">
        {/* HEADER */}
        <div className="w-full h-62.5 bg-[#0D1D24] rounded-t-3xl">
          <div className="flex items-center gap-3 ml-10 mb-5 pt-10">
            <div className="flex-center w-10 h-10 rounded-xl bg-white">
              <Image
                src="/logo.png"
                width={1200}
                height={1200}
                alt="logo"
                className="w-[90%] h-[90%]"
              />
            </div>

            <span className="text-indigo-50 text-xl font-medium">
              KubeMonitor
            </span>
          </div>

          {/* NAVIGATION */}
          <div className="flex flex-wrap gap-2 ml-10">
            <a href="#overview" className="flex items-center gap-2">
              <MdOutlineDashboard />
              <span>Overview</span>
            </a>

            {/* <a href="#monitoring" className="flex items-center gap-2">
              <MdOutlineMonitorHeart />
              <span>Monitoring</span>
            </a> */}

            <a href="#pods" className="flex items-center gap-2">
              <LiaCubesSolid />
              <span>Pods</span>
            </a>

            <a href="#cicd" className="flex items-center gap-2">
              <FaCodeBranch />
              <span>CI/CD</span>
            </a>

            <a href="#deployments" className="flex items-center gap-2">
              <IoRocketOutline />
              <span>Deployments</span>
            </a>

            <a href="#events" className="flex items-center gap-2">
              <FaRegFileLines />
              <span>Events</span>
            </a>
          </div>
        </div>

        {/* MAIN DASHBOARD */}
        <div className="w-[90%] m-auto py-10">
          <div id="overview">
            {/* OVERVIEW HEADER */}
            <div className="flex items-center gap-5">
              <div>
                <div className="flex items-center gap-5 basis-1/2">
                  <h1>Overview</h1>

                  {loading && !data ? (
                    <div className="rounded-full px-3 py-1 bg-gray-200">
                      Loading...
                    </div>
                  ) : (
                    <div
                      className={`flex items-center gap-2 rounded-full px-2 py-1 w-fit ${
                        allHealthy
                          ? "bg-green-100 text-green-700"
                          : "bg-red-100 text-red-700"
                      }`}
                    >
                      <div
                        className={`w-2 h-2 rounded-full ${
                          allHealthy ? "bg-green-500" : "bg-red-500"
                        }`}
                      />

                      <p>
                        {error
                          ? "Monitoring data unavailable"
                          : allHealthy
                            ? "All Systems are healthy"
                            : "System needs attention"}
                      </p>
                    </div>
                  )}
                </div>

                <p>
                  Live health and deployment status for your EKS application.
                </p>
              </div>

              {/* SIMULATION BUTTONS */}
              <div className="flex basis-1/2 gap-4">
                <button
                  onClick={simulateCPU}
                  disabled={simulating}
                  className="text-[18px] flex items-center gap-2 w-fit text-white font-medium cursor-pointer 
                  bg-main transition-all duration-300 ease-in-out hover:bg-secondary py-3 px-3 rounded-xl 
                  drop-shadow-lg disabled:opacity-50"
                >
                  <BsCpu />
                  <span>{simulating ? "Starting..." : "CPU Spike"}</span>
                </button>

                <button
                  onClick={simulatePodCrash}
                  disabled={crashing}
                  className="text-[18px] flex items-center gap-2 w-fit text-white font-medium cursor-pointer 
                  bg-main transition-all duration-300 ease-in-out hover:bg-secondary py-3 px-3 rounded-xl 
                  drop-shadow-lg disabled:opacity-50"
                >
                  <RiFlashlightLine />
                  <span>{crashing ? "Triggering..." : "Pod Crashes"}</span>
                </button>
              </div>
            </div>

            {/* API ERROR */}
            {error && (
              <p role="alert" className="mt-5 text-red-600 text-sm">
                API Error: {error}
              </p>
            )}


            {/* OVERVIEW CARDS */}
            <div className="flex flex-wrap items-center gap-5 mt-10">
              {/* Cluster Health */}
              <OverviewCard
  title="Cluster Health"
  icon={allHealthy ? <LuShieldCheck /> : <LuShieldAlert />}
  result={!data ? "N/A" : allHealthy ? "Healthy" : "Degraded"}
  description="Nodes, Pods and Deployments"
  status={!data ? "gray" : allHealthy ? "green" : "red"}
/>

              {/* Worker Nodes */}
              <OverviewCard
                title="Worker Nodes"
                icon={<TbServer />}
                result={workerNodes}
                description="Nodes ready"
                status="blue"
              />

              {/* Running Pods */}
              <OverviewCard
                title="Running Pods"
                icon={<BiCube />}
                result={runningPods}
                description="Desired replicas ready"
                status="blue"
              />

              {/* CPU Usage */}
              <OverviewCard
                title="CPU Usage"
                icon={<BsCpu />}
                result={cpuUsage}
                description="EKS worker node CPU"
                status={cpuStatus}
              />

              {/* Node Memory */}
              <OverviewCard
                title="Node Memory"
                icon={<BsMemory />}
                result={memoryUsage}
                description="EKS worker node memory"
                status={memoryStatus}
              />

              {/* Deployment Health */}
              <OverviewCard
                title="Deployment Health"
                icon={<FaCodeBranch />}              
                result={deploymentHealth}                
                description="Desired replicas ready"
                status={deploymentStatus}
              />
            </div>

            {/* EXISTING DASHBOARD COMPONENTS */}
            <div id="monitoring">{/* <Monitor /> */}</div>

            <div id="pods">
              <Pods pods={data?.kubernetes?.pods?.details ?? []} />
            </div>

            <div id="cicd">{/* <Branches /> */}</div>

            <div id="events">
              <Events />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
