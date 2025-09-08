package config

import (
	"fmt"

	"github.com/spf13/viper"
)

type Client struct {
	ID        string
	Secret    string
	ServerURL string `mapstructure:"serverUrl" yaml:"serverUrl"`
}

func LoadClient() (*Client, error) {
	v := viper.New()

	// Set defaults
	v.SetDefault("server_url", "localhost:8080")

	// Config file settings
	v.SetConfigName("config")
	v.SetConfigType("yaml")

	// Search paths
	v.AddConfigPath("$HOME/.byte/")

	// Try to read config file
	err := v.ReadInConfig()
	if err != nil {
		return nil, fmt.Errorf("error reading config file: %w", err)
	}

	var cfg Client

	err = v.Unmarshal(&cfg)
	if err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}
