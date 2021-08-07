# Create GatewaySubnet
az network vnet subnet create \
--vnet-name vnet01 \
-n GatewaySubnet \
-g handson \
--address-prefix 10.100.100.0/24

# Create Public IP
az network public-ip create \
-n hjvnetGWPip \
-g handson \
--allocation-method Dynamic

# Create Gateway
az network vnet-gateway create \
-n hjvnetGW \
-l eastus \
--public-ip-address hjvnetGWPip \
-g handson \
--vnet vnet01 \
--gateway-type Vpn \
--sku VpnGw1 \
--vpn-type RouteBased \
--no-wait