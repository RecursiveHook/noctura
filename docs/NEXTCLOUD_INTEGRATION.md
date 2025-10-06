# NextCloud Integration (Roadmap)

Future integration between Noctura and NextCloud for enhanced file management and collaboration.

## Planned Features

### Phase 1: Basic Integration
- [ ] WebDAV mount for large attachments
- [ ] Sync Obsidian attachments to NextCloud
- [ ] Shared folder for vault attachments
- [ ] Automatic backup to NextCloud storage

### Phase 2: Advanced Features
- [ ] Collaborative vault editing
- [ ] NextCloud Notes integration
- [ ] Calendar integration for daily notes
- [ ] Sharing via NextCloud public links

### Phase 3: Full Integration
- [ ] NextCloud client app for Obsidian
- [ ] Real-time collaboration
- [ ] Version history from NextCloud
- [ ] Integration with NextCloud Office

## Current Workarounds

### Manual WebDAV Sync

1. Install [Remotely Save](https://github.com/remotely-save/remotely-save) plugin
2. Configure WebDAV connection to NextCloud
3. Use for attachment sync only (CouchDB for notes)

### Attachment Folder Sync

Mount NextCloud WebDAV as attachment folder:

```bash
# Linux example
sudo apt install davfs2
sudo mount -t davfs https://nextcloud.example.com/remote.php/dav/files/user/ /mnt/nextcloud
```

Then configure Obsidian attachment path to `/mnt/nextcloud/obsidian-attachments`

## Architecture Proposal

```
┌─────────────────┐
│  Obsidian App   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌──────────┐
│ CouchDB │ │NextCloud │
│ (Notes) │ │ (Files)  │
└─────────┘ └──────────┘
```

- CouchDB: Text notes, metadata, fast sync
- NextCloud: Attachments, PDFs, large files, sharing

## Configuration (Future)

### docker-compose.yml Addition

```yaml
services:
  nextcloud:
    image: nextcloud:latest
    container_name: noctura-nextcloud
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - nextcloud-data:/var/www/html
      - ./data/attachments:/var/www/html/data/attachments
    environment:
      - MYSQL_HOST=db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=${NEXTCLOUD_DB_PASSWORD}
    networks:
      - noctura-net

  db:
    image: mariadb:10.11
    container_name: noctura-mariadb
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=${NEXTCLOUD_DB_PASSWORD}
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - noctura-net

volumes:
  nextcloud-data:
  db-data:
```

## Plugin Development Ideas

Custom Obsidian plugin to bridge CouchDB and NextCloud:

- Auto-detect attachment types
- Route large files to NextCloud
- Keep small files in CouchDB
- Seamless user experience

## Community Feedback

We're looking for feedback on NextCloud integration:

1. What features are most important?
2. Should attachments be in CouchDB or NextCloud?
3. Performance vs. features tradeoffs?
4. Self-hosted only or support NextCloud providers?

## Timeline

- Q2 2025: Basic WebDAV support
- Q3 2025: Attachment sync automation
- Q4 2025: Collaboration features

## Contributing

Interested in helping with NextCloud integration?

1. Check [GitHub Issues](../../issues) for tasks
2. Join discussion in [Discussions](../../discussions)
3. Submit PRs for NextCloud features

## References

- [NextCloud WebDAV](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html)
- [Obsidian API](https://github.com/obsidianmd/obsidian-api)
- [Remotely Save Plugin](https://github.com/remotely-save/remotely-save)

---

**Status**: 📋 Planning Phase - Community input welcome!
