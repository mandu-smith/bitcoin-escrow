# Contributing to Bitcoin Escrow Smart Contract

We love your input! We want to make contributing to this smart contract as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github

We use Github to host code, to track issues and feature requests, as well as accept pull requests.

## Development Process

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code lints
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](LICENSE) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using Github's [issue tracker](../../issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](../../issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Smart Contract Specific Guidelines

### State Changes

When modifying contract state:

1. Always validate inputs thoroughly
2. Check authorization before state changes
3. Emit appropriate events for tracking
4. Update all relevant state variables atomically
5. Add appropriate error handling

### Testing

- Write tests for all new functionality
- Include both positive and negative test cases
- Test edge cases thoroughly
- Ensure all tests pass before submitting PR

### Documentation

- Update relevant documentation
- Document all new functions and state variables
- Include examples for complex functionality
- Update error code documentation if changed

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
