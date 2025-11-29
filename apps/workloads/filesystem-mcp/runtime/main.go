package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	filesystemserver "github.com/mark3labs/mcp-filesystem-server/filesystemserver"
	mcpserver "github.com/mark3labs/mcp-go/server"
)

const (
	defaultPort          = "8080"
	defaultAllowedRoot   = "/host"
	destructiveToolToken = "ALLOW_MUTATING_TOOLS"
)

var destructiveTools = []string{
	"write_file",
	"create_directory",
	"copy_file",
	"move_file",
	"delete_file",
	"modify_file",
}

func main() {
	cfg := loadConfig()

	mcpSrv, err := filesystemserver.NewFilesystemServer(cfg.allowedDirs)
	if err != nil {
		log.Fatalf("failed to construct filesystem MCP server: %v", err)
	}

	if !cfg.allowMutations {
		mcpSrv.DeleteTools(destructiveTools...)
	}

	streamable := mcpserver.NewStreamableHTTPServer(
		mcpSrv,
		mcpserver.WithStateLess(true),
		mcpserver.WithHeartbeatInterval(30*time.Second),
	)

	mux := http.NewServeMux()
	mux.Handle("/mcp", withSecurityHeaders(cfg.nodeName, streamable))
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		addSecurityHeaders(w, cfg.nodeName)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":    "ok",
			"node":      cfg.nodeName,
			"readOnly":  fmt.Sprintf("%t", !cfg.allowMutations),
			"roots":     strings.Join(cfg.allowedDirs, ","),
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	})

	addr := fmt.Sprintf(":%s", cfg.port)
	log.Printf("filesystem MCP gateway listening on %s (node=%s, allowMutations=%t, roots=%v)",
		addr, cfg.nodeName, cfg.allowMutations, cfg.allowedDirs)

	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 15 * time.Second,
	}

	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("server exited with error: %v", err)
	}
}

type config struct {
	port           string
	nodeName       string
	allowedDirs    []string
	allowMutations bool
}

func loadConfig() config {
	port := strings.TrimSpace(os.Getenv("PORT"))
	if port == "" {
		port = defaultPort
	}

	nodeName := os.Getenv("NODE_NAME")

	allowedRaw := os.Getenv("ALLOWED_DIRECTORIES")
	if allowedRaw == "" {
		allowedRaw = defaultAllowedRoot
	}

	allowedDirs := make([]string, 0)
	for _, part := range strings.Split(allowedRaw, ",") {
		path := strings.TrimSpace(part)
		if path == "" {
			continue
		}
		allowedDirs = append(allowedDirs, path)
	}
	if len(allowedDirs) == 0 {
		allowedDirs = []string{defaultAllowedRoot}
	}

	allowMutations := strings.EqualFold(os.Getenv(destructiveToolToken), "true")

	return config{
		port:           port,
		nodeName:       nodeName,
		allowedDirs:    allowedDirs,
		allowMutations: allowMutations,
	}
}

func withSecurityHeaders(node string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		addSecurityHeaders(w, node)
		next.ServeHTTP(w, r)
	})
}

func addSecurityHeaders(w http.ResponseWriter, node string) {
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-Frame-Options", "DENY")
	if node != "" {
		w.Header().Set("X-Node-Name", node)
	}
}
