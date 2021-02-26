if [ $(egrep -c '(vmx|svm)' /proc/cpuinfo) -eq 0 ]; then 
cat > /etc/nova/nova-compute.conf << EOF
[DEFAULT]
compute_driver=libvirt.LibvirtDriver
[libvirt]
virt_type=qemu
EOF
fi

