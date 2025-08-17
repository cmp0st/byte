package config

import (
	"fmt"

	"github.com/spf13/viper"
)

type Config struct {
	Host           string    `mapstructure:"host" yaml:"host"`
	Port           int       `mapstructure:"port" yaml:"port"`
	HostKey        string    `mapstructure:"host_key" yaml:"host_key"`
	AuthorizedKeys []string  `mapstructure:"authorized_keys" yaml:"authorized_keys"`
	Posix          *Posix    `mapstructure:"posix" yaml:"posix"`
	InMemory       *InMemory `mapstructure:"in_memory" yaml:"in_memory"`
}

type Posix struct {
	Root string `mapstructure:"root" yaml:"root"`
}

type InMemory struct{}

func Load() (*Config, error) {
	v := viper.New()

	// Set defaults
	v.SetDefault("host", "localhost")
	v.SetDefault("port", 2222)
	v.SetDefault("posix.root", "./data")

	// Config file settings
	v.SetConfigName("config")
	v.SetConfigType("yaml")

	// Search paths
	v.AddConfigPath("/etc/byte/")
	v.AddConfigPath(".")

	// Try to read config file
	if err := v.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("error reading config file: %w", err)
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}
