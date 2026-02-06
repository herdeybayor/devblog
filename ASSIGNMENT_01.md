# DevOps Mentorship - Assignment 1

## Docker Compose Helper Script

**Cohort:** C2  
**Session Date:** January 25, 2026  
**Due Date:** Before next session

---

## Objective

By completing this assignment, you will:

1. Reinforce your understanding of Docker and Docker Compose by setting up the DevBlog project
2. Learn to create utility bash scripts that simplify repetitive DevOps tasks
3. Practice writing maintainable shell scripts with proper argument handling

---

## Prerequisites

Before starting this assignment, ensure you have:

- [ ] Docker installed and running on your machine
- [ ] Docker Compose installed (comes with Docker Desktop)
- [ ] The DevBlog project cloned to your local machine
- [ ] Basic understanding of bash scripting

---

## Part 1: Project Setup (Review)

Ensure your project has the following files properly configured from our session:

### 1.1 Dockerfile

Your `Dockerfile` should:

- Use an appropriate Node.js base image
- Set the working directory
- Copy package files and install dependencies
- Copy application code
- Expose the application port
- Define the startup command

### 1.2 .dockerignore

Your `.dockerignore` file should exclude:

- `node_modules/`
- `.env` files
- `.git/`
- Any other files that shouldn't be in the container

### 1.3 docker-compose.yml

Your `docker-compose.yml` must include three services:

| Service         | Image/Build            | Port  | Purpose               |
| --------------- | ---------------------- | ----- | --------------------- |
| `web`           | Build from Dockerfile  | 3000  | Node.js application   |
| `mongo`         | `mongo:latest`         | 27017 | MongoDB database      |
| `mongo-express` | `mongo-express:latest` | 8081  | MongoDB web interface |

**Important configurations:**

- The `web` service should depend on `mongo`
- The `web` service should use `mongo` as the database host (not `localhost`)
- Use an `env_file` to pass environment variables to the `web` service
- Mongo Express should be configured to connect to the `mongo` service

### 1.4 Environment File

Create a `docker.env` file (or similar) with the necessary environment variables for:

- MongoDB connection string (using `mongo` as the host)
- Any application-specific variables
- Mongo Express credentials

---

## Part 2: Main Assignment - Create `dc-helper.sh`

Your task is to create a bash script called `dc-helper.sh` that serves as a helper utility for common Docker Compose operations.

### 2.1 Requirements

The script must implement the following commands:

```
DevBlog Docker Compose Helper
=============================

Usage: ./dc-helper.sh <command> [service]

Commands:
  up [service]          Start all services, or a specific service
  down [service]        Stop all services, or a specific service
  build [service]       Build all services, or a specific service
  restart [service]     Restart all services, or a specific service
  logs [service]        View logs (all or specific). Use -f to follow
  status [service]      Show status of all or a specific container
  seed                  Create admin user (run seeding script)
  shell <service>       Open a shell inside a container (e.g., web, mongo)
  clean                 Stop containers and remove volumes (DESTRUCTIVE)
  help                  Show this help message

Services:
  web                   Node.js application (port 3000)
  mongo                 MongoDB database (port 27017)
  mongo-express         MongoDB web UI (port 8081)

Examples:
  ./dc-helper.sh up                 # Start all services
  ./dc-helper.sh up mongo           # Start only MongoDB
  ./dc-helper.sh down web           # Stop only web service
  ./dc-helper.sh logs -f            # Follow all logs
  ./dc-helper.sh logs web           # View only web service logs
  ./dc-helper.sh build web          # Rebuild only web service
  ./dc-helper.sh restart mongo      # Restart only MongoDB
  ./dc-helper.sh status             # Check all container statuses
  ./dc-helper.sh shell web          # Open shell in web container
  ./dc-helper.sh shell mongo        # Open MongoDB shell
  ./dc-helper.sh seed               # Seed database with admin user
  ./dc-helper.sh clean              # Full cleanup (removes data!)
```

### 2.2 Command Specifications

| Command   | Behavior                                                                 |
| --------- | ------------------------------------------------------------------------ |
| `up`      | Runs services in detached mode (`-d` flag)                               |
| `down`    | Stops and removes containers                                             |
| `build`   | Builds or rebuilds service images                                        |
| `restart` | Restarts running containers                                              |
| `logs`    | Shows container logs. Must support `-f` flag for following logs          |
| `status`  | Shows container status using `docker compose ps`                         |
| `seed`    | Executes `node create-user-cli.js` inside the `web` container            |
| `shell`   | Opens an interactive shell. For `mongo` service, open `mongosh`          |
| `clean`   | Stops containers AND removes volumes (warn the user this is destructive) |
| `help`    | Displays the help message shown above                                    |

### 2.3 Hints

Here are some hints to help you implement the script:

#### Bash Basics

1. **Shebang**: Start your script with `#!/bin/bash` to specify the interpreter

2. **Arguments**: Access command-line arguments using:

   - `$1` - First argument (the command)
   - `$2` - Second argument (the service or flag)
   - `$@` - All arguments
   - `$#` - Number of arguments

3. **Case Statement**: Use a `case` statement to route commands:
   ```bash
   case $1 in
       command1)
           # do something
           ;;
       command2)
           # do something else
           ;;
       *)
           # default/unknown command
           ;;
   esac
   ```

#### Docker Compose Commands

4. **Starting services**: `docker compose up -d [service]`

5. **Stopping services**: `docker compose down` or `docker compose stop [service]`

6. **Viewing logs**: `docker compose logs [service]` or `docker compose logs -f [service]`

7. **Container status**: `docker compose ps [service]`

8. **Execute command in container**: `docker compose exec <service> <command>`

9. **Remove volumes**: `docker compose down -v`

#### Special Cases

10. **Logs with -f flag**: You'll need to check if `$2` is `-f` and handle it differently from a service name

11. **Shell command**:

    - For the `web` container, use `/bin/sh` or `/bin/bash`
    - For the `mongo` container, use `mongosh` to open the MongoDB shell

12. **Making the script executable**: After creating the script, run `chmod +x dc-helper.sh`

---

## Part 3: Testing Your Script

Test each command to ensure it works correctly:

```bash
# Make the script executable
chmod +x dc-helper.sh

# Test help
./dc-helper.sh help

# Start all services
./dc-helper.sh up

# Check status
./dc-helper.sh status

# View logs
./dc-helper.sh logs
./dc-helper.sh logs web
./dc-helper.sh logs -f

# Seed the database
./dc-helper.sh seed

# Open shells
./dc-helper.sh shell web
./dc-helper.sh shell mongo

# Restart a service
./dc-helper.sh restart web

# Clean up
./dc-helper.sh clean
```

---

## Submission Requirements

Submit the following:

1. **`dc-helper.sh`** - Your completed bash script
2. **`docker-compose.yml`** - Your Docker Compose configuration (if modified)
3. **Screenshot** - Terminal output showing `./dc-helper.sh help` working

### Submission Method

Push your changes to your GitHub repository and share the link.

---

## Grading Criteria

| Criteria                                                       | Points  |
| -------------------------------------------------------------- | ------- |
| Script displays help message correctly                         | 10      |
| `up` and `down` commands work (with and without service)       | 15      |
| `build` and `restart` commands work (with and without service) | 15      |
| `logs` command works (with service and -f flag)                | 15      |
| `status` command works                                         | 10      |
| `seed` command works                                           | 10      |
| `shell` command works for both web and mongo                   | 15      |
| `clean` command works                                          | 10      |
| **Total**                                                      | **100** |

---

## Bonus Challenges (Optional)

For extra practice, try implementing these enhancements:

1. **Color Output**: Add colored output to make the script more user-friendly (green for success, red for errors, yellow for warnings)

2. **Validation**: Add validation to check if Docker is running before executing commands

3. **Service Validation**: Check if the provided service name is valid (web, mongo, or mongo-express)

4. **Confirmation Prompt**: Add a confirmation prompt before running the `clean` command

5. **Health Check**: Add a `health` command that checks if all services are running and healthy

---

## Resources

- [Docker Compose CLI Reference](https://docs.docker.com/compose/reference/)
- [Bash Scripting Tutorial](https://www.gnu.org/software/bash/manual/bash.html)
- [Shell Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)

---

Good luck! If you have questions, reach out in the Discord channel.
