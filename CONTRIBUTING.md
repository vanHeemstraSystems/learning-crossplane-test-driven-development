# Contributing to Crossplane TDD

Thank you for your interest in contributing to this Crossplane TDD learning repository! 🎉

## 🤝 How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [GitHub Issues](https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development/issues)
1. If not, create a new issue with:
- Clear title and description
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Your environment (OS, tool versions)

### Suggesting Enhancements

We welcome suggestions for:

- New test examples
- Additional XRD/Composition patterns
- Documentation improvements
- Tool integrations
- Best practices

### Submitting Pull Requests

1. **Fork the repository**
   
   ```bash
   git clone https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development.git
   cd learning-crossplane-test-driven-development
   ```
1. **Create a feature branch**
   
   ```bash
   git checkout -b feature/my-improvement
   ```
1. **Make your changes**
- Follow existing code style
- Update documentation
- Add tests if applicable
1. **Test your changes**
   
   ```bash
   # Run unit tests
   ./scripts/test/run-unit-tests.sh
   
   # Validate policies
   ./scripts/validate/validate-policies.sh
   ```
1. **Commit with clear messages**
   
   ```bash
   git add .
   git commit -m "feat: Add PostgreSQL high availability example"
   ```
   
   Commit message format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks
1. **Push and create PR**
   
   ```bash
   git push origin feature/my-improvement
   ```
   
   Then create a Pull Request on GitHub

## 📝 Contribution Guidelines

### Code Style

**Shell Scripts:**

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Add comments for complex logic
- Use meaningful variable names
- Follow existing formatting

**YAML:**

- 2 spaces for indentation
- Use comments to explain complex configurations
- Keep files under 500 lines
- Use descriptive resource names

**Documentation:**

- Use clear, concise language
- Include code examples
- Add metaphors where helpful (Fast Food theme!)
- Keep paragraphs short
- Use headers for navigation

### Testing Requirements

All contributions should include:

✅ **For new XRDs/Compositions:**

- Schema validation tests
- Policy compliance tests
- At least one integration test example
- Documentation in README

✅ **For new features:**

- Unit tests
- Integration tests (if applicable)
- Updated documentation

✅ **For bug fixes:**

- Test that reproduces the bug
- Fix that makes test pass
- Updated documentation

### Documentation Standards

When adding documentation:

1. **Be beginner-friendly** - Assume reader is new to Crossplane
1. **Use examples** - Show, don’t just tell
1. **Keep it practical** - Focus on real-world usage
1. **Maintain consistency** - Follow existing structure
1. **Use the metaphor** - Fast Food Restaurant theme throughout

## 🎯 Areas We Need Help

### High Priority

- [ ] More XRD examples (different Azure services)
- [ ] AWS provider examples
- [ ] GCP provider examples
- [ ] Complex composition patterns
- [ ] Performance optimization guides

### Medium Priority

- [ ] Video tutorials
- [ ] Interactive examples
- [ ] Troubleshooting guides
- [ ] CI/CD pipeline examples
- [ ] GitOps integration examples

### Low Priority

- [ ] Translations
- [ ] Advanced testing patterns
- [ ] Custom composition functions
- [ ] Monitoring dashboards

## 🔍 Review Process

1. **Automated Checks**
- All tests must pass
- Code style checks
- Documentation builds
1. **Peer Review**
- At least one approval required
- Constructive feedback expected
- Changes may be requested
1. **Merge**
- Squash and merge preferred
- Clear commit message in main branch

## 💬 Communication

- **Questions?** Open a [GitHub Discussion](https://github.com/vanHeemstraSystems/learning-crossplane-test-driven-development/discussions)
- **Ideas?** Start a discussion or create an issue
- **Chat?** Join [Crossplane Slack](https://slack.crossplane.io/)

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Our Standards

**Positive behaviors:**

- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards others

**Unacceptable behaviors:**

- Trolling, insulting/derogatory comments
- Personal or political attacks
- Harassment of any kind
- Publishing others’ private information
- Other conduct inappropriate in a professional setting

### Enforcement

Violations can be reported to [wvanheemstra@icloud.com]. All complaints will be reviewed and investigated.

## 🎓 Learning Resources

New to contributing? Check out:

- [First Contributions](https://github.com/firstcontributions/first-contributions)
- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

## 🙏 Recognition

All contributors will be recognized in our [Contributors](#) section.

Thank you for making this project better! 🚀

-----

**Questions?** Feel free to ask - we’re here to help! 💙
