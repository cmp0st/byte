package auth

import "context"

type contextKey struct{}

func DeviceFromContext(ctx context.Context) string {
	device, ok := ctx.Value(contextKey{}).(string)
	if !ok {
		return ""
	}

	return device
}

func WithDevice(ctx context.Context, device string) context.Context {
	return context.WithValue(ctx, contextKey{}, device)
}
