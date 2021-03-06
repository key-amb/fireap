# fireap [![Build Status](https://travis-ci.org/progrhyme/fireap.svg?branch=master)](https://travis-ci.org/progrhyme/fireap)

Consul-based rapid propagative task runner for large systems.

### Table of Contents

* [Overview](#overview)
  * [What's this?](#whats-this)
  * [Benchmark](#benchmark)
  * [About Consul](#about-consul)
  * [Take a look at how it works](#take-a-look-at-how-it-works)
  * [Task Propagation Procedure](#task-propagation-procedure)
    * [Publisher and Subscribers](#publisher-and-subscribers)
    * [Procedure](#procedure)
    * [Consul Kv](#consul-kv)
* [How to get started?](#how-to-get-started)

# Overview

## What's this?

This program triggers to execute configured tasks on nodes in **_Consul
Cluster_**.
And tasks will be executed in propagative way.  
Task propagation time takes _O(log N)_ in theory; as _N_ means node number in
cluster.

So this tool can shorten the time of tasks which take _O(N)_ time in system of
large number of nodes.  
Typical usecase is software deployment.

The name **fireap** comes from _"fire"_ and _"reap"_.

## Benchmark

Here is a benchmark result comparing **fireap** against
[GNU Parallel](http://www.gnu.org/software/parallel/).

|      | GNU Parallel | fireap    |
| ---- | ------------:|----------:|
| real |    0m46.906s | 0m18.992s |
| user |    0m40.407s | 0m00.527s |
| sys  |    0m04.241s | 0m00.046s |

The job executed here is a directory sync operation by `rsync` command which
contains a thousand of files up to total 12MB size, through 100 t2.micro instances
on AWS EC2.

Concurrency numbers of both _GNU Parallel_ and _fireap_ is 5 in this benchmark.

In _fireap_, the word _"concurrency"_ means the maximum concurrent number that
one node can be "pulled" by other nodes.  
You will grasp the concept by going under part of this document.

## About Consul

[Consul](https://www.consul.io/) is a tool for service discovery and infrastructure
automation developed and produced by [HashiCorp](https://www.hashicorp.com/).

## Take a look at how it works

Below is a demo of **fireap** task propagation at a 10-node Consul cluster.

![Fireap Demo](https://raw.githubusercontent.com/progrhyme/fireap/resource/image/fireap-demo.gif)

On the top of the screen, `fireap monitor` command is executed.
This continuously shows the application version and updated information of nodes
those are stored in _Consul Kv_.

On the bottom of the screen, `fireap fire` command is executed which fires _Consul
Event_.
The triggered event is broadcasted to cluster members at once.  
And it leads cluster members to execute `fireap reap` command by _Consul Watch_
mechanism.

Eventually, configured tasks are executed on nodes in the cluster.

## Task Propagation Procedure

The image below illustrates task propagation procedure by **fireap** in Consul cluster.

![Fireap Task Propagation Illustration](https://raw.githubusercontent.com/progrhyme/fireap/resource/image/fireap-propagation.png)

### Publisher and Subscribers

One _publisher_ node fires Consul events whose `Name` is `FIREAP:TASK`.
And it is assumed to be the 1st node in the cluster which finishes the task.  
All other nodes are _subscribers_ who receive events and execute tasks.

Concept of _publisher_ and _subscriber_ is not related to role of _server_ and _client_
in Consul.  
_Server_ or _client_ in Consul cluster can be either _publisher_ or _subscriber_.

### Procedure

1. _Publisher_ fires a Consul event.
2. The event is broadcasted for appropriate _subscribers_ at once.
3. _Subscribers_ execute the task in propagative way:
  1. All _subscribers_ search for a finished node in the cluster to "pull" update
     information or contents from the node.  
     In first stage, there is only _publisher_ who finished the task.
     So they all tries to "pull" from _publisher_, but maximum number of who can
     "pull" from a particular node is limited by configuration.
     Then, only several _subscribers_ succeed to "pull" and execute the task.
  2. In second stage, _publisher_ and several _subscribers_ now finished the task.
     Their update will be "pulled" by other _subscribers_.
  3. Stage goes on until all _subscribers_ finish the task.

This propagation way looks like tree branching.  
But it is rather robust because even if a _subscriber_ happens to fail the task, the
failure does not affect others.

### Consul Kv

_Publisher_ and _subscribers_ store information in _Consul Kv_ about task completion and so on.  
All keys of data related to this program begin with prefix `fireap/`.

# How to get started?

You can start **fireap** with the guide in [Documentation](http://progrhyme.github.io/fireap-doc/).

# LICENSE

The MIT License (MIT)

Copyright (c) 2016-2017 IKEDA Kiyoshi
