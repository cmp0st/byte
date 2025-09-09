package config

import (
	"fmt"

	"github.com/spf13/viper"
)

type Server struct {
	LogLevel string `mapstructure:"logLevel" yaml:"logLevel"`
	Secret   string `mapstructure:"secret"   yaml:"secret"`

	SFTP SFTP `mapstructure:"sftp" yaml:"sftp"`
	HTTP HTTP `mapstructure:"http" yaml:"http"`

	Storage  Storage `mapstructure:"storage" yaml:"storage"`
	Database string
}

type SFTP struct {
	Host           string   `mapstructure:"host"           yaml:"host"`
	Port           int      `mapstructure:"port"           yaml:"port"`
	AuthorizedKeys []string `mapstructure:"authorizedKeys" yaml:"authorizedKeys"`
}

type HTTP struct {
	Host string `mapstructure:"host" yaml:"host"`
	Port int    `mapstructure:"port" yaml:"port"`
}

type Storage struct {
	Posix    *Posix    `mapstructure:"posix"    yaml:"posix"`
	InMemory *InMemory `mapstructure:"inMemory" yaml:"inMemory"`
}

type Posix struct {
	Root string `mapstructure:"root" yaml:"root"`
}

type InMemory struct{}

const (
	DefaultHTTPPort = 8080
	DefaultSSHPort  = 8022
)

func LoadServer() (*Server, error) {
	v := viper.New()

	// Set defaults
	v.SetDefault("sftp.host", "localhost")
	v.SetDefault("sftp.port", DefaultSSHPort)
	v.SetDefault("http.host", "localhost")
	v.SetDefault("http.port", DefaultHTTPPort)
	v.SetDefault("posix.root", "./data")
	v.SetDefault("database", "byte.db")

	// Config file settings
	v.SetConfigName("config")
	v.SetConfigType("yaml")

	// Search paths
	v.AddConfigPath("/etc/byte/")
	v.AddConfigPath(".")

	// Try to read config file
	err := v.ReadInConfig()
	if err != nil {
		return nil, fmt.Errorf("error reading config file: %w", err)
	}

	var cfg Server

	err = v.Unmarshal(&cfg)
	if err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}
