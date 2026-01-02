# From React to Phoenix: A Developer's Field Guide

Welcome to the bridge. You know React, Node, and SQL. Now you're stepping into the world of Elixir, Phoenix, and the BEAM.

This tutorial series is designed to map your existing mental models (Components, State, APIs) to the Phoenix way of doing things. We've broken it down into 6 distinct parts, analyzing this specific application (`cuetube`) to explain the concepts.

## Table of Contents

### [Part 1: The Blueprint (Stack & Structure)](01_intro_and_stack.md)
**The "Kitchen"**
We start with the high-level architecture. Where is `package.json`? Where does the code live? Why is there no "Frontend" folder? We map the project structure to what you already know.

### [Part 2: The Vault (Data & Ecto)](02_data_and_ecto.md)
**The "Data Layer"**
Forget ORMs as you know them. Ecto is different. We explore Schemas (Data Shape), Changesets (Validation), and Contexts (Business Logic) using the `User` model as our guide.

### [Part 3: The Traffic Controller (Router & Request)](03_router_and_request.md)
**The "Maître D'"**
How does a URL become a page? We trace the life of a request through the Router, Pipelines (Middleware), and Scopes. We also explain how Authentication (OAuth) flows through the system.

### [Part 4: The Heartbeat (LiveView Basics)](04_liveview_basics.md)
**The "Engine"**
The core of the magic. We dissect `DashboardLive` to understand how Phoenix renders HTML on the server, sends it to the client, and handles user interactions (Clicks, Form Submits) without writing a single API endpoint.

### [Part 5: The Face (UI & Components)](05_ui_and_components.md)
**The "Presentation"**
How do we style it? We look at HEEx (HTML + EEx), Core Components (your internal UI library), and how Tailwind CSS and DaisyUI fit into the picture.

### [Part 6: The Phone Call (External APIs)](06_external_apis.md)
**The "Outside World"**
We look at `lib/cuetube/youtube/client.ex` to see how Elixir handles external HTTP requests using `Req`, pattern matching on responses, and keeping secrets safe.

---

## How to Read This
I recommend reading them in order. Open the referenced file in your editor as you read each part.

*   **Code:** `lib/cuetube_web/live/dashboard_live.ex`
*   **Guide:** [Part 4: LiveView Basics](04_liveview_basics.md)

Happy coding!

