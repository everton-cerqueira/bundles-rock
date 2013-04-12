require 'models/blueprints/sensors'
require 'models/blueprints/timestamping'

# The module under which all device models are defined
module Dev
    # The module under which all communication busses are defined
    module Bus
    end

    # The module under which all sensors are defined
    module Sensors
        device_type 'GPS' do
            provides Base::PositionSrv
        end
        device_type 'Hokuyo' do
            provides Base::LaserRangeFinderSrv
        end
        device_type 'XsensAHRS' do
            provides Base::OrientationSrv
            provides Base::CalibratedIMUSensorsSrv
        end

        # Base namespace for all camera device models
        module Cameras
            device_type 'Firewire' do
                provides Base::ImageProviderSrv
            end
        end
    end

    # The module under which platforms are declared. Platforms are e.g. mobile
    # platforms, vehicles, ...
    module Platforms
    end

    # Simulated platforms and sensors
    module Simulation
    end

    # Actuators
    module Actuators
        device_type 'PTU'
    end
end

