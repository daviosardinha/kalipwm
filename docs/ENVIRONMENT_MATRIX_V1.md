# Environment behavior matrix

| Behavior | Bare metal | VMware guest | VirtualBox guest | KVM/QEMU guest |
|---|---:|---:|---:|---:|
| Physical XRandR topology | yes | no | no | no |
| External position preference | yes | no | no | no |
| VMware guest packages | no | yes | no | no |
| `vmware-user-suid-wrapper` | no | yes | no | no |
| VirtualBox guest packages | no | no | yes | no |
| SPICE/QEMU guest packages | no | no | no | yes |
| Battery widget | auto | auto | auto | auto |
| Backlight keys | present; effective when sysfs backlight exists | harmless | harmless | harmless |
| Network/VPN modules | dynamic | dynamic | dynamic | dynamic |
| Flameshot | yes | yes | yes | yes |
