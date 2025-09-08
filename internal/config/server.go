package config

import (
	"fmt"

	"github.com/spf13/viper"
)

type Server struct {
	LogLevel string `mapstructure:"log_level" yaml:"log_level"`
	Secret   string `mapstructure:"secret"    yaml:"secret"`

	SFTP SFTP `mapstructure:"sftp" yaml:"sftp"`
	HTTP HTTP `mapstructure:"http" yaml:"http"`

	Storage Storage `mapstructure:"storage" yaml:"storage"`
}

type SFTP struct {
	Host           string   `mapstructure:"host"            yaml:"host"`
	Port           int      `mapstructure:"port"            yaml:"port"`
	AuthorizedKeys []string `mapstructure:"authorized_keys" yaml:"authorized_keys"`
}

type HTTP struct {
	Host string `mapstructure:"host" yaml:"host"`
	Port int    `mapstructure:"port" yaml:"port"`
}

type Storage struct {
	Posix    *Posix    `mapstructure:"posix"     yaml:"posix"`
	InMemory *InMemory `mapstructure:"in_memory" yaml:"in_memory"`
	S3       *S3       `mapstructure:"s3"        yaml:"s3"`
}

type Posix struct {
	Root string `mapstructure:"root" yaml:"root"`
}

type InMemory struct{}

type S3 struct {
	Bucket    string `mapstructure:"bucket"     yaml:"bucket"`
	Region    string `mapstructure:"region"     yaml:"region"`
	Endpoint  string `mapstructure:"endpoint"   yaml:"endpoint"`
	AccessKey string `mapstructure:"access_key" yaml:"access_key"`
	SecretKey string `mapstructure:"secret_key" yaml:"secret_key"`
	UseSSL    *bool  `mapstructure:"use_ssl"    yaml:"use_ssl"`
}

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

	var cfg Server
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}
